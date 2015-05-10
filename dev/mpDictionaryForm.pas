unit mpDictionaryForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, Grids, ValEdit,
  mpBase, mpLogger;

type
  TDictionaryForm = class(TForm)
    ListView1: TListView;
    Memo1: TMemo;
    Splitter1: TSplitter;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    ValueListEditor1: TValueListEditor;
    Panel4: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure ListView1Change(Sender: TObject; Item: TListItem;
      Change: TItemChange);
    procedure ListView1Data(Sender: TObject; Item: TListItem);
    procedure ValueListEditor1DrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure ListView1ColumnClick(Sender: TObject; Column: TListColumn);
    procedure ListView1DrawItem(Sender: TCustomListView; Item: TListItem;
      Rect: TRect; State: TOwnerDrawState);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

const
  red = TColor($0000FF);
  yellow = TColor($00A8E5);
  green = TColor($009000);

var
  DictionaryForm: TDictionaryForm;
  columnToSort: integer;
  ascending: boolean;

implementation

{$R *.dfm}

procedure TDictionaryForm.ValueListEditor1DrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
begin
  ValueListEditor1.Canvas.Brush.Color := clWhite;
  ValueListEditor1.Canvas.FillRect(Rect);
  Rect.Left := Rect.Left + 2;
  DrawText(ValueListEditor1.Canvas.Handle,
    PChar(ValueListEditor1.Cells[aCol, ARow]), -1, Rect,
    DT_SINGLELINE or DT_LEFT OR DT_VCENTER or DT_NOPREFIX);
end;

function PluginCount(var list: TList): integer;
var
  i: Integer;
  entry: TEntry;
  sl: TStringList;
begin
  sl := TStringList.Create;
  sl.Sorted := true;
  sl.Duplicates := dupIgnore;
  for i := 0 to Pred(list.Count) do begin
    entry := TEntry(list[i]);
    sl.Add(entry.pluginName);
  end;
  Result := sl.Count;
  sl.Free;
end;

function ReportCount(var list: TList): integer;
var
  i: Integer;
  entry: TEntry;
begin
  Result := 0;
  for i := 0 to Pred(list.Count) do begin
    entry := TEntry(list[i]);
    Result := Result + StrToInt(entry.reports);
  end;
end;

procedure TDictionaryForm.FormCreate(Sender: TObject);
var
  s: string;
begin
  // initialize listview
  columnToSort := -1;
  ListView1.OwnerDraw := not settings.simpleDictionaryView;
  ListView1.Items.Count := dictionary.Count;

  // read dictionary details
  ValueListEditor1.InsertRow('Filename', 'dictionary.txt', true);
  s := FormatByteSize(GetFileSize('dictionary.txt'));
  ValueListEditor1.InsertRow('File size', s, true);
  s := DateTimeToStr(GetLastModified('dictionary.txt'));
  ValueListEditor1.InsertRow('Date modified', s, true);
  s := IntToStr(dictionary.Count);
  ValueListEditor1.InsertRow('Number of entries', s, true);
  s := IntToStr(PluginCount(dictionary));
  ValueListEditor1.InsertRow('Number of plugins', s, true);
  s := IntToStr(ReportCount(dictionary));
  ValueListEditor1.InsertRow('Number of reports', s, true);
  s := IntToStr(blacklist.Count);
  ValueListEditor1.InsertRow('Blacklist size', s, true);
end;

procedure TDictionaryForm.ListView1Change(Sender: TObject; Item: TListItem;
  Change: TItemChange);
var
  entry: TEntry;
begin
  if ListView1.ItemIndex = -1 then
    exit;

  entry := TEntry(dictionary[ListView1.ItemIndex]);
  Memo1.Text := StringReplace(entry.notes, '@13', #13#10, [rfReplaceAll]);
end;

function CompareAsFloat(s1, s2: string): Integer;
var
  f1, f2: Real;
begin
  try
    f1 := StrToFloat(s1);
  except on Exception do
    f1 := 0;
  end;
  try
    f2 := StrToFloat(s2);
  except on Exception do
    f2 := 0;
  end;

  if f1 = f2 then
    Result := 0
  else if f1 > f2 then
    Result := 1
  else
    Result := -1;
end;

function CompareEntries(P1, P2: Pointer): Integer;
var
  entry1, entry2: TEntry;
begin
  Result := 0;
  entry1 := TEntry(P1);
  entry2 := TEntry(P2);

  if columnToSort = 0 then
    Result := AnsiCompareText(entry1.pluginName, entry2.pluginName)
  else if columnToSort = 1 then
    Result := StrToInt(entry1.records) - StrToInt(entry2.records)
  else if columnToSort = 2 then
    Result := CompareAsFloat(entry1.version, entry2.version)
  else if columnToSort = 3 then
    Result := CompareAsFloat(entry1.rating, entry2.rating)
  else if columnToSort = 4 then
    Result := StrToInt(entry1.reports) - StrToInt(entry2.reports);

  if ascending then
    Result := -Result;
end;

procedure TDictionaryForm.ListView1ColumnClick(Sender: TObject;
  Column: TListColumn);
begin
  ascending := (columnToSort = Column.Index) and (not ascending);
  columnToSort := Column.Index;
  dictionary.Sort(CompareEntries);
  ListView1.Repaint;
  ListView1Change(nil, nil, TItemChange(nil));
end;

procedure TDictionaryForm.ListView1Data(Sender: TObject; Item: TListItem);
var
  entry: TEntry;
begin
  entry := TEntry(dictionary[Item.Index]);
  Item.Caption := entry.pluginName;
  Item.SubItems.Add(entry.records);
  Item.SubItems.Add(entry.version);
  Item.SubItems.Add(entry.rating);
  Item.SubItems.Add(entry.reports);
  ListView1.Canvas.Font.Color := GetRatingColor(StrToFloat(entry.rating));
  ListView1.Canvas.Font.Style := ListView1.Canvas.Font.Style + [fsBold];
end;

procedure TDictionaryForm.ListView1DrawItem(Sender: TCustomListView;
  Item: TListItem; Rect: TRect; State: TOwnerDrawState);
var
  i, x, y: integer;
begin
  if Item.Selected then begin
    TListView(Sender).Canvas.Brush.Color := $FFEEDD;
    TListView(Sender).Canvas.FillRect(Rect);
  end;
  x := Rect.Left + 3;
  y := (Rect.Bottom - Rect.Top - TListView(Sender).Canvas.TextHeight('Hg')) div 2 + Rect.Top;
  TListView(Sender).Canvas.TextOut(x, y, Item.Caption);
  for i := 0 to Item.SubItems.Count - 1 do begin
    inc(x, TListView(Sender).Columns[i].Width);
    TListView(Sender).Canvas.TextOut(x, y, Item.SubItems[i]);
  end;
end;

end.
