unit KM_ResFontsEdit;
{$I KaM_Remake.inc}
interface
uses
  Windows,
  {$IFDEF FPC} lconvencoding, {$ENDIF}
  Classes, Graphics, Math, SysUtils, Types,
  KM_CommonTypes, KM_ResFonts;


type
  //Child class that has the advanced editing methods
  TKMFontDataEdit = class(TKMFontData)
  private
    fTexPadding: Byte;
  public
    procedure CreateFont(aFontName: string; aFontSize: Byte; aFontStyle: TFontStyles; aAntialias: Boolean; const aChars: array of WideChar);
    procedure CollateFont(aFonts: array of TKMFontDataEdit; aCodepages: array of Word);
    procedure ImportPng(const aFilename: string);
    procedure SaveToFont(const aFilename: string);
    procedure SaveToFontX(const aFilename: string);

    property TexData: TKMCardinalArray read fTexData;
    property TexPadding: Byte read fTexPadding write fTexPadding;
    property TexSizeX: Word read fTexSizeX write fTexSizeX;
    property TexSizeY: Word read fTexSizeY write fTexSizeY;
    property IsUnicode: Boolean read fIsUnicode;

    property CharSpacing: SmallInt read fCharSpacing write fCharSpacing;
    property LineSpacing: Byte read fLineSpacing write fLineSpacing;
    property BaseHeight: SmallInt read fBaseHeight write fBaseHeight;
    property WordSpacing: SmallInt read fWordSpacing write fWordSpacing;
    property Unknown: SmallInt read fUnknown write fUnknown;
  end;


implementation
uses KM_PNG;


{ TKMFontDataEdit }
procedure TKMFontDataEdit.CreateFont(aFontName: string; aFontSize: Byte; aFontStyle: TFontStyles; aAntialias: Boolean; const aChars: array of WideChar);
const
  FONT_INTERLINE = 5; //Spacing between lines of text
var
  bitmap: TBitmap;
  I, K, pX, pY: Integer;
  chWidth: Byte;
  chRect: TRect;
  txtHeight: Integer;
  ch: UnicodeString;
begin
  bitmap := TBitmap.Create;
  try
    bitmap.PixelFormat := pf32bit;
    bitmap.Width := fTexSizeX;
    bitmap.Height := fTexSizeY;
    bitmap.Canvas.Font.Color := clWhite;
    bitmap.Canvas.Font.Size := aFontSize;
    bitmap.Canvas.Font.Name := aFontName;
    bitmap.Canvas.Font.Style := aFontStyle;
    if aAntialias then
      bitmap.Canvas.Font.Quality := fqClearType
    else
      bitmap.Canvas.Font.Quality := fqNonAntialiased;

    //Common font props
    fBaseHeight := aFontSize;
    fWordSpacing := 4;
    fCharSpacing := 0;
    fLineSpacing := FONT_INTERLINE;

    txtHeight := bitmap.Canvas.TextHeight('"_pI|,');

    //Characters we gonna use
    FillChar(Used, SizeOf(Used), #0);
    for I := Low(aChars) to High(aChars) do
      Used[Ord(aChars[I])] := 1;

    //Obtain each characters dimensions (KaM char heights are per-char, so we do the same)
    for I := 0 to High(Word) do
    if Used[I] <> 0 then
    begin
      ch := WideChar(I); //Lazarus needs extra verbose types
      Letters[I].Width := bitmap.Canvas.TextWidth(UTF8Encode(ch));
      Letters[I].Height := txtHeight;
    end;

    bitmap.Canvas.Brush.Style := bsSolid;
    bitmap.Canvas.Brush.Color := clBlack;
    bitmap.Canvas.FillRect(Rect(0, 0, fTexSizeX, fTexSizeY));

    pX := fTexPadding;
    pY := fTexPadding;
    for I := 0 to High(Word) do
    if Used[I] <> 0 then
    begin
      chWidth := Letters[I].Width;

      if chWidth = 0 then Continue;

      if pX + chWidth + fTexPadding*2 >= fTexSizeX then
      begin
        pX := fTexPadding;
        Inc(pY, txtHeight + fTexPadding*2);
        if pY + txtHeight + fTexPadding*2 > fTexSizeY then
          Break;
      end;

      Letters[I].u1 := (pX - fTexPadding) / fTexSizeX;
      Letters[I].v1 := (pY - fTexPadding) / fTexSizeY;
      Letters[I].u2 := (pX + chWidth + fTexPadding) / fTexSizeX;
      Letters[I].v2 := (pY + txtHeight + fTexPadding) / fTexSizeY;

      chRect.Left := pX;
      chRect.Top := pY;
      chRect.Right := pX + chWidth;
      chRect.Bottom := pY + txtHeight;
      ch := WideChar(I); //Lazarus needs extra verbose types
      bitmap.Canvas.TextRect(chRect, pX, pY, UTF8Encode(ch));

      Inc(pX, chWidth + fTexPadding*2);
    end;

    SetLength(fTexData, fTexSizeX * fTexSizeY);

    //Only Alpha will be used to generate the texture to avoid rimming
    for I := 0 to bitmap.Height - 1 do
    for K := 0 to bitmap.Width - 1 do
      fTexData[(I * bitmap.Width + K)] := Cardinal(bitmap.Canvas.Pixels[K, I] shl 24) or $FFFFFF;

  finally
    bitmap.Free;
  end;
end;


//Create font by collating several different codepages
procedure TKMFontDataEdit.CollateFont(aFonts: array of TKMFontDataEdit; aCodepages: array of Word);
  function AnsiCharToWideChar(ac: AnsiChar; CodePage: Word): WideChar;
  begin
    if MultiByteToWideChar(CodePage, 0, @ac, 1, @Result, 1) <> 1 then
      RaiseLastOSError;
  end;
const
  INS = 0;
var
  I, K, L, M, pX, pY: Integer;
  chWidth, chHeight, lineHeight: Byte;
  srcX, srcY: Word;
  dstPixel, srcPixel: Cardinal;
  uniChar: Char;
  uniCode: Word;
begin
  //Common font props are presumably the same for all codepages
  fBaseHeight := aFonts[0].BaseHeight;
  fWordSpacing := aFonts[0].WordSpacing;
  fCharSpacing := aFonts[0].CharSpacing;
  fLineSpacing := aFonts[0].LineSpacing;

  //Atlas line height
  lineHeight := 0;
  for I := 0 to 255 do
  if aFonts[0].Used[I] <> 0 then
    lineHeight := Math.max(lineHeight, aFonts[0].Letters[I].Height);

  //Texture data
  SetLength(fTexData, fTexSizeX * fTexSizeY);

  pX := fTexPadding;
  pY := fTexPadding;
  for K := Low(aFonts) to High(aFonts) do
    for I := 0 to aFonts[K].CharCount do
    begin
      if aFonts[K].Used[I] = 0 then Continue;

      if aFonts[K].IsUnicode then
        uniChar := WideChar(I)
      else
        uniChar := AnsiCharToWideChar(AnsiChar(I), aCodepages[K]);

      uniCode := Ord(uniChar);

      //We already have that letter
      if Used[uniCode] <> 0 then Continue;

      chWidth := aFonts[K].Letters[I].Width;
      chHeight := aFonts[K].Letters[I].Height;

      if chWidth = 0 then Continue;

      if pX + chWidth + fTexPadding >= fTexSizeX then
      begin
        pX := fTexPadding;
        Inc(pY, lineHeight + fTexPadding);
        if pY + lineHeight + fTexPadding >= fTexSizeY then
          Exit;
      end;

      //Copy the character over
      for M := 0 to chHeight - 1 do
      for L := 0 to chWidth - 1 do
      begin
        srcX := Round(aFonts[K].Letters[I].u1 * aFonts[K].fTexSizeX);
        srcY := Round(aFonts[K].Letters[I].v1 * aFonts[K].fTexSizeY);
        srcPixel := (srcY + M) * aFonts[K].fTexSizeX + srcX + L;
        dstPixel := (pY + M) * fTexSizeX + pX + L;
        fTexData[dstPixel] := aFonts[K].fTexData[srcPixel];
      end;

      Used[uniCode] := 1;
      Letters[uniCode].Width := chWidth;
      Letters[uniCode].Height := chHeight;
      Letters[uniCode].YOffset := aFonts[K].Letters[I].YOffset;
      Letters[uniCode].u1 := (pX + INS) / fTexSizeX;
      Letters[uniCode].v1 := (pY + INS) / fTexSizeY;
      Letters[uniCode].u2 := (pX + chWidth - INS) / fTexSizeX;
      Letters[uniCode].v2 := (pY + chHeight - INS) / fTexSizeY;

      Inc(pX, chWidth + fTexPadding);
    end;
end;


procedure TKMFontDataEdit.ImportPng(const aFilename: string);
var
  I, K: Word;
  pngWidth, pngHeight: Word;
  pngData: TKMCardinalArray;
begin
  LoadFromPng(aFilename, pngWidth, pngHeight, pngData);

  Assert((pngWidth = fTexSizeX) and (pngHeight = fTexSizeY), 'Size must match because of letters data');

  for I := 0 to fTexSizeY - 1 do
  for K := 0 to fTexSizeX - 1 do
    (PCardinal(Cardinal(@fTexData[0]) + (I * fTexSizeX + K) * 4))^ := pngData[I * fTexSizeX + K];
end;


procedure TKMFontDataEdit.SaveToFont(const aFilename: string);
var
  I: Byte;
  S: TMemoryStream;
begin
  S := TMemoryStream.Create;
  try
    S.Write(fBaseHeight, 2);
    S.Write(fWordSpacing, 2);
    S.Write(fCharSpacing, 2);
    S.Write(fUnknown, 2); //Unknown field

    S.Write(Used[0], 256);

    //Write font data
    for I := 0 to 255 do
    if Used[I] <> 0 then
    begin
      S.Write(Letters[I].Width, 2);
      S.Write(Letters[I].Height, 2);
      S.Write(Letters[I].Unknown1, 2); //Unknown field
      S.Write(Letters[I].Unknown2, 2); //Unknown field
      S.Write(Letters[I].YOffset, 2);
      S.Write(Letters[I].Unknown3, 2); //Unknown field

      S.Write(rawData[I,0], Letters[I].Width * Letters[I].Height);
    end;

    S.SaveToFile(aFilename);
  finally
    S.Free;
  end;
end;


//Save font in extended format (with unicode and 32bit support)
procedure TKMFontDataEdit.SaveToFontX(const aFilename: string);
const
  FNTX_HEAD: AnsiString = 'FNTX';
var
  S: TMemoryStream;
  I: Integer;
begin
  S := TMemoryStream.Create;
  try
    //Header
    S.Write(FNTX_HEAD[1], 4);

    //Base font properties
    S.Write(fBaseHeight, 2);
    S.Write(fWordSpacing, 2);
    S.Write(fCharSpacing, 2);
    S.Write(fLineSpacing, 1);

    //Letters data
    S.Write(Used[0], Length(Used) * SizeOf(Used[0]));
    for I := 0 to High(Word) do
    if Used[I] <> 0 then
      S.Write(Letters[I], SizeOf(TKMLetter));

    //Texture data
    S.Write(fTexSizeX, 2);
    S.Write(fTexSizeY, 2);
    S.Write(fTexData[0], fTexSizeX * fTexSizeY * 4);

    S.SaveToFile(aFilename);
  finally
    S.Free;
  end;
end;


end.