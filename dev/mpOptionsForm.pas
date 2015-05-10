unit mpOptionsForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, Buttons, ImgList, FileCtrl,
  mpBase,
  wbInterface;

type
  TOptionsForm = class(TForm)
    SettingsPageControl: TPageControl;
    GeneralTabSheet: TTabSheet;
    MergingTabSheet: TTabSheet;
    Label1: TLabel;
    cbLanguage: TComboBox;
    GroupBox1: TGroupBox;
    kbSimpleDictionary: TCheckBox;
    kbSimplePlugins: TCheckBox;
    btnCancel: TButton;
    btnOK: TButton;
    GroupBox2: TGroupBox;
    kbUsingMO: TCheckBox;
    Label2: TLabel;
    edMODirectory: TEdit;
    btnDetect: TButton;
    kbCopyGeneral: TCheckBox;
    btnBrowseMO: TSpeedButton;
    IconList: TImageList;
    GroupBox3: TGroupBox;
    Label3: TLabel;
    edMergeDirectory: TEdit;
    btnBrowseAssetDirectory: TSpeedButton;
    kbFaceGen: TCheckBox;
    kbVoiceAssets: TCheckBox;
    kbTranslations: TCheckBox;
    kbFragments: TCheckBox;
    kbExtractBSAs: TCheckBox;
    kbBuildBSA: TCheckBox;
    GroupBox4: TGroupBox;
    kbUpdateDictionary: TCheckBox;
    kbUpdateProgram: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnBrowseAssetDirectoryClick(Sender: TObject);
    procedure btnBrowseMOClick(Sender: TObject);
    procedure kbUsingMOClick(Sender: TObject);
    procedure btnDetectClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  OptionsForm: TOptionsForm;

implementation

{$R *.dfm}

procedure TOptionsForm.btnBrowseAssetDirectoryClick(Sender: TObject);
var
  s: string;
begin
  // different SelectDirectory starting paths
  if DirectoryExists(edMergeDirectory.Text) then
    s := edMergeDirectory.Text
  else if kbUsingMO.Checked and DirectoryExists(edMODirectory.Text) then
    s := edMODirectory.Text;
  // prompt user to select a directory
  SelectDirectory('Select a directory', '', s, []);

  // save text to TEdit
  if s <> '' then
    edMergeDirectory.Text := AppendIfMissing(s, '\');
end;

procedure TOptionsForm.btnBrowseMOClick(Sender: TObject);
var
  s: string;
begin
  // start in current directory value if valid
  if DirectoryExists(edMODirectory.Text) then
    s := edMODirectory.Text;
  // prompt user to select a directory
  SelectDirectory('Select a directory', '', s, []);

  // save text to TEdit
  if s <> '' then
    edMODirectory.Text := AppendIfMissing(s, '\');
end;

procedure TOptionsForm.btnCancelClick(Sender: TObject);
begin
  // discard settings
  settings.Free;

  // close with ModalResult
  ModalResult := mrCancel;
end;

procedure TOptionsForm.btnDetectClick(Sender: TObject);
var
  i: integer;
  modOrganizerPath, paths: string;
  pathList, ignore: TStringList;
  rec: TSearchRec;
begin
  // search for installations in ?:\Program Files and ?:\Program Files (x86)
  for i := 65 to 90 do begin
    if DirectoryExists(chr(i) + ':\Program Files') then
      paths := paths + chr(i) + ':\Program Files;';
    if DirectoryExists(chr(i) + ':\Program Files (x86)') then
      paths := paths + chr(i) + ':\Program Files (x86);';
  end;

  modOrganizerPath := FileSearch('Mod Organizer\ModOrganizer.exe', paths);

  // search for installations in GamePath
  if (modOrganizerPath = '') then begin
    ignore := TStringList.Create;
    ignore.Add('data');
    modOrganizerPath := RecursiveFileSearch('ModOrganizer.exe', wbDataPath + '..\', ignore, 2);
  end;

  // search each folder in each valid Program Files directory for ModOrganizer.exe
  if (modOrganizerPath = '') then begin
    pathList := TStringList.Create;
    while (Pos(';', paths) > 0) do begin
      pathList.Add(Copy(paths, 1, Pos(';', paths) - 1));
      paths := Copy(paths, Pos(';', paths) + 1, Length(paths));
    end;
    for i := 0 to pathList.Count - 1 do begin
      if FindFirst(pathList[i] + '\*', faDirectory, rec) = 0 then begin
        repeat
          modOrganizerPath := FileSearch('ModOrganizer.exe', pathList[i] + '\' + rec.Name);
          if (modOrganizerPath <> '') then
            break;
        until FindNext(rec) <> 0;

        FindClose(rec);
        if (modOrganizerPath <> '') then break;
      end;
    end;
  end;

  // if found, set TEdit captions, else alert user
  if (modOrganizerPath <> '') then begin
    edMODirectory.Text := Copy(modOrganizerPath, 1, length(modOrganizerPath) - 16);
    edMergeDirectory.Text := edMODirectory.Text + 'mods\';
  end
  else begin
    MessageDlg('Couldn''t automatically detect Mod Organizer''s file path.  Please enter it manually.', mtConfirmation, [mbOk], 0);
    edMODirectory.Text := '';
  end;
end;

procedure TOptionsForm.btnOKClick(Sender: TObject);
begin
  // save changes to settings
  settings.language := cbLanguage.Text;
  settings.simpleDictionaryView := kbSimpleDictionary.Checked;
  settings.simplePluginsView := kbSimplePlugins.Checked;
  settings.updateDictionary := kbUpdateDictionary.Checked;
  settings.updateProgram := kbUpdateProgram.Checked;
  settings.usingMO := kbUsingMO.Checked;
  settings.MODirectory := edMODirectory.Text;
  settings.copyGeneralAssets := kbCopyGeneral.Checked;
  settings.mergeDirectory := edMergeDirectory.Text;
  settings.handleFaceGenData := kbFaceGen.Checked;
  settings.handleVoiceAssets := kbVoiceAssets.Checked;
  settings.handleMCMTranslations := kbTranslations.Checked;
  settings.handleScriptFragments := kbFragments.Checked;
  settings.extractBSAs := kbExtractBSAs.Checked;
  settings.buildMergedBSA := kbBuildBSA.Checked;
  settings.Save('settings.ini');

  // close with ModalResult
  ModalResult := mrOk;
end;

procedure TOptionsForm.FormCreate(Sender: TObject);
begin
  // load setting
  cbLanguage.Text := settings.language;
  kbSimpleDictionary.Checked := settings.simpleDictionaryView;
  kbSimplePlugins.Checked := settings.simplePluginsView;
  kbUpdateDictionary.Checked := settings.updateDictionary;
  kbUpdateProgram.Checked := settings.updateProgram;
  kbUsingMO.Checked := settings.usingMO;
  edMODirectory.Text := settings.MODirectory;
  kbCopyGeneral.Checked := settings.copyGeneralAssets;
  edMergeDirectory.Text := settings.mergeDirectory;
  kbFaceGen.Checked := settings.handleFaceGenData;
  kbVoiceAssets.Checked := settings.handleVoiceAssets;
  kbTranslations.Checked := settings.handleMCMTranslations;
  kbFragments.Checked := settings.handleScriptFragments;
  kbExtractBSAs.Checked := settings.extractBSAs;
  kbBuildBSA.Checked := settings.buildMergedBSA;

  // disable controls if not using mod organizer
  kbUsingMOClick(nil);

  // set up buttons
  btnBrowseMO.Flat := true;
  btnBrowseAssetDirectory.Flat := true;
  IconList.GetBitmap(0, btnBrowseMO.Glyph);
  IconList.GetBitmap(0, btnBrowseAssetDirectory.Glyph);
end;

procedure TOptionsForm.kbUsingMOClick(Sender: TObject);
var
  b: boolean;
begin
  b := kbUsingMO.Checked;
  edMODirectory.Enabled := b;
  btnDetect.Enabled := b;
  btnBrowseMO.Enabled := b;
  kbCopyGeneral.Enabled := b;
end;

end.
