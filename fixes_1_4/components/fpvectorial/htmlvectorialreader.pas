{
Reads a HTML Document

License: The same modified LGPL as the Free Pascal RTL
         See the file COPYING.modifiedLGPL for more details

AUTHORS: Felipe Monteiro de Carvalho
}
unit htmlvectorialreader;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, math, contnrs,
  fpimage, fpcanvas, laz2_xmlread, laz2_dom, fgl,
  // image data formats
  fpreadpng,
  // HTML can contain SVG
  svgvectorialreader,
  fpvectorial, fpvutils, lazutf8, TypInfo;

type
  { TvHTMLVectorialReader }

  TvHTMLVectorialReader = class(TvCustomVectorialReader)
  private
    FPointSeparator, FCommaSeparator: TFormatSettings;
    //
    function ReadEntityFromNode(ANode: TDOMNode; AData: TvTextPageSequence; ADoc: TvVectorialDocument): TvEntity;
    function ReadHeaderFromNode(ANode: TDOMNode; AData: TvTextPageSequence; ADoc: TvVectorialDocument): TvEntity;
    function ReadParagraphFromNode(ANode: TDOMNode; AData: TvTextPageSequence; ADoc: TvVectorialDocument): TvEntity;
    function ReadSVGFromNode(ANode: TDOMNode; AData: TvTextPageSequence; ADoc: TvVectorialDocument): TvEntity;
    function ReadMathFromNode(ANode: TDOMNode; AData: TvTextPageSequence; ADoc: TvVectorialDocument): TvEntity;
  public
    { General reading methods }
    constructor Create; override;
    Destructor Destroy; override;
    procedure ReadFromStrings(AStrings: TStrings; AData: TvVectorialDocument); override;
    procedure ReadFromXML(Doc: TXMLDocument; AData: TvVectorialDocument);
  end;

implementation

const
  // SVG requires hardcoding a DPI value

  // The Opera Browser and Inkscape use 90 DPI, so we follow that

  // 1 Inch = 25.4 milimiters
  // 90 inches per pixel = (1 / 90) * 25.4 = 0.2822
  // FLOAT_MILIMETERS_PER_PIXEL = 0.3528; // DPI 72 = 1 / 72 inches per pixel

  FLOAT_MILIMETERS_PER_PIXEL = 5*0.2822; // DPI 90 = 1 / 90 inches per pixel => Actually I changed the value by this factor! Because otherwise it looks ugly!
  FLOAT_PIXELS_PER_MILIMETER = 1 / FLOAT_MILIMETERS_PER_PIXEL; // DPI 90 = 1 / 90 inches per pixel

{ TvHTMLVectorialReader }

function TvHTMLVectorialReader.ReadEntityFromNode(ANode: TDOMNode;
  AData: TvTextPageSequence; ADoc: TvVectorialDocument): TvEntity;
var
  lEntityName: DOMString;
begin
  Result := nil;
  lEntityName := LowerCase(ANode.NodeName);
  case lEntityName of
    'h1', 'h2', 'h3', 'h4', 'h5', 'h6': Result := ReadHeaderFromNode(ANode, AData, ADoc);
    'p': Result := ReadParagraphFromNode(ANode, AData, ADoc);
    'svg': Result := ReadSVGFromNode(ANode, AData, ADoc);
    'math': Result := ReadMathFromNode(ANode, AData, ADoc);
  end;
end;

function TvHTMLVectorialReader.ReadHeaderFromNode(ANode: TDOMNode;
  AData: TvTextPageSequence; ADoc: TvVectorialDocument): TvEntity;
var
  CurParagraph: TvParagraph;
  lText: TvText;
  lTextStr: string;
  lHeaderType: DOMString;
begin
  Result := nil;
  CurParagraph := AData.AddParagraph();
  CurParagraph.Style := ADoc.StyleTextBody;
  lTextStr := ANode.FirstChild.NodeValue;
  lText := CurParagraph.AddText(lTextStr);
  lHeaderType := LowerCase(ANode.NodeName);
  case lHeaderType of
    'h1': lText.Style := ADoc.StyleHeading1;
    'h2': lText.Style := ADoc.StyleHeading2;
    'h3': lText.Style := ADoc.StyleHeading3;
    'h4': lText.Style := ADoc.StyleHeading4;
    'h5': lText.Style := ADoc.StyleHeading5;
    'h6': lText.Style := ADoc.StyleHeading6;
  end;
end;

function TvHTMLVectorialReader.ReadParagraphFromNode(ANode: TDOMNode;
  AData: TvTextPageSequence; ADoc: TvVectorialDocument): TvEntity;
var
  CurParagraph: TvParagraph;
  lText: TvText;
  lTextStr: string;
begin
  Result := nil;
  CurParagraph := AData.AddParagraph();
  CurParagraph.Style := ADoc.StyleTextBody;
  lTextStr := ANode.FirstChild.NodeValue;
  lText := CurParagraph.AddText(lTextStr);
end;

function TvHTMLVectorialReader.ReadSVGFromNode(ANode: TDOMNode;
  AData: TvTextPageSequence; ADoc: TvVectorialDocument): TvEntity;
var
  CurSVG: TvEmbeddedVectorialDoc;
  lText: TvText;
  lDoc: TXMLDocument;
  lImportedNode: TDOMNode;
begin
  Result := nil;
  CurSVG := AData.AddEmbeddedVectorialDoc();
  lDoc := TXMLDocument.Create;
  try
    lImportedNode := lDoc.ImportNode(ANode, True);
    lDoc.AppendChild(lImportedNode);
    CurSVG.Document.ReadFromXML(lDoc, vfSVG);
  finally
    lDoc.Free;
  end;
end;

function TvHTMLVectorialReader.ReadMathFromNode(ANode: TDOMNode;
  AData: TvTextPageSequence; ADoc: TvVectorialDocument): TvEntity;
var
  CurSVG: TvEmbeddedVectorialDoc;
  lText: TvText;
  lDoc: TXMLDocument;
  lImportedNode: TDOMNode;
begin
  Result := nil;
  CurSVG := AData.AddEmbeddedVectorialDoc();
  lDoc := TXMLDocument.Create;
  try
    lImportedNode := lDoc.ImportNode(ANode, True);
    lDoc.AppendChild(lImportedNode);
    CurSVG.Document.ReadFromXML(lDoc, vfMathML);
  finally
    lDoc.Free;
  end;
end;

constructor TvHTMLVectorialReader.Create;
begin
  inherited Create;

  FPointSeparator := DefaultFormatSettings;
  FPointSeparator.DecimalSeparator := '.';
  FPointSeparator.ThousandSeparator := '#';// disable the thousand separator
end;

destructor TvHTMLVectorialReader.Destroy;
begin
  inherited Destroy;
end;

procedure TvHTMLVectorialReader.ReadFromStrings(AStrings: TStrings;
  AData: TvVectorialDocument);
var
  Doc: TXMLDocument = nil;
  lStream: TMemoryStream;
  lTmp: String;
begin
  lStream := TMemoryStream.Create();
  try
    // Remove the <!DOCTYPE line
    if Pos('<!DOCTYPE', AStrings.Strings[0]) <> 0 then
      AStrings.Delete(0);
    // Create a header
    AStrings.Insert(0, '<?xml version="1.0"?>');
    lTmp := AStrings.Text;
    // Flush it back to a stream
    AStrings.SaveToStream(lStream);
    lStream.Position := 0;
    // HTML is not XML, but might be compatible enough... a dedicated reader will be complex, but eventually necessary
    ReadXMLFile(Doc, lStream);
    lStream.Free; // Release as soon as unnecessary
    lStream := nil;
    //
    ReadFromXML(Doc, AData);
  finally
    Doc.Free;
    lStream.Free;
  end;
end;

procedure TvHTMLVectorialReader.ReadFromXML(Doc: TXMLDocument;
  AData: TvVectorialDocument);
var
  lCurNode, lCurSubnode: TDOMNode;
  lPage: TvTextPageSequence;
  lNodeName, lNodeValue: DOMString;
  ANode: TDOMElement;
  i: Integer;
  lCurEntity: TvEntity;
begin
  {ANode := Doc.DocumentElement;
  for i := 0 to ANode.Attributes.Length - 1 do
  begin
    lNodeName := ANode.Attributes.Item[i].NodeName;
    lNodeValue := ANode.Attributes.Item[i].NodeValue;
  end;}

  AData.AddStandardTextDocumentStyles(vfHTML);

  // ----------------
  // Now process the elements
  // ----------------
  lCurNode := Doc.DocumentElement.FirstChild;
  lPage := AData.AddTextPageSequence();
  //lPage.Width := AData.Width;
  //lPage.Height := AData.Height;
  while Assigned(lCurNode) do
  begin
    lNodeName := lCurNode.NodeName;
    if lNodeName = 'body' then
    begin
      lCurSubnode := lCurNode.FirstChild;
      while Assigned(lCurSubnode) do
      begin
        lCurEntity := ReadEntityFromNode(lCurSubnode, lPage, AData);
        if lCurEntity <> nil then
          lPage.AddEntity(lCurEntity);

        lCurSubnode := lCurSubnode.NextSibling;
      end;
    end;

    lCurNode := lCurNode.NextSibling;
  end;
end;

initialization

  RegisterVectorialReader(TvHTMLVectorialReader, vfHTML);

end.

