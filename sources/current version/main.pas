unit main;

{$mode objfpc}{$H+}

interface

uses
  // Dev Add
  ElgWOL, FilesManager, Windows,
  // Automatic Add
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  Buttons, ExtCtrls, StdCtrls;

type

  { TForm1 }

  TForm1 = class(TForm)
    BtnAdd: TSpeedButton;
    BtnRemove: TSpeedButton;
    Image1: TImage;
    ImageBackground: TImage;
    ListMAC: TListView;
    BtnWakeup: TSpeedButton;
    procedure ConfigLoad;
    procedure ConfigSave;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure BtnAddClick(Sender: TObject);
    procedure BtnRemoveClick(Sender: TObject);
    procedure BtnWakeupClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }
procedure TForm1.ConfigLoad;
var
  i: Integer;
  dataName, dataMac: TStringList;
  NewColumn: TListColumn;
  NewRow: TListItem;
begin
  ListMAC.Clear;
  NewColumn := ListMAC.Columns.Add;
  NewColumn.Caption := 'Name';
  NewColumn.Width := 110;
  NewColumn := ListMAC.Columns.Add;
  NewColumn.Caption := 'MAC';
  NewColumn.Width := 110;
  // Load
  if not FileExists('NameList.txt') then Exit;
  dataName := FilesManager.ReadFileToStringList('NameList.txt');
  if not FileExists('MacList.txt') then Exit;
  dataMac := FilesManager.ReadFileToStringList('MacList.txt');
  if dataName.Count = 0 then Exit;
  if dataMac.Count = 0 then Exit;
  for i := 0 to dataName.Count -1 do
  begin
    NewRow := ListMAC.Items.Add;
    NewRow.Caption := dataName.Strings[i];
    if i < dataMac.Count then
      NewRow.SubItems.Add(dataMac.Strings[i]);
  end;

end;

procedure TForm1.ConfigSave;
var
  i: Integer;
  data: TStringList;
begin
  // Save Name
  data := TStringList.Create;
  for i := 0 to ListMAC.Items.Count -1 do
    data.Add(ListMAC.Items.Item[i].Caption);
  if data.Count = 0 then Exit;
  FilesManager.WriteStringListInFile('NameList.txt', data);
  if not FileExists('NameList.txt') then MessageBoxA( Handle, PChar('Warning : Database save fail!'), PChar('Warning'), MB_ICONERROR );
  // Save Mac
  data := TStringList.Create;
  for i := 0 to ListMAC.Items.Count -1 do
    data.Add(ListMAC.Items.Item[i].SubItems[0]);
  if data.Count = 0 then Exit;
  FilesManager.WriteStringListInFile('MacList.txt', data);
  if not FileExists('MacList.txt') then MessageBoxA( Handle, PChar('Warning : Database save fail!'), PChar('Warning'), MB_ICONERROR );
end;

procedure TForm1.BtnWakeupClick(Sender: TObject);
var
  Cmpt : Integer;
begin
  if ( ListMAC.Items.Count = 0 ) then
  begin
    MessageBoxA( Handle, PChar('First, add a computer in list!'), PChar('Stop'), MB_ICONWARNING );
    Exit;
  end;
  BtnWakeup.Enabled := False;
  for Cmpt := 0 to ( ListMAC.Items.Count - 1 ) do
  begin
    GoWOL( ListMAC.Items.Item[Cmpt].SubItems[0] );
    Sleep( 1500 );
  end;
  BtnWakeup.Enabled := True;
end;



procedure TForm1.FormCreate(Sender: TObject);
var
  mac: String;
begin
  // Command line (use: WakeOnLan.exe "MAC")
  if ParamCount() > 0 then
  begin
    mac := LowerCase(ParamStr(1));
    GoWOL(mac);
    Application.Terminate;
    Exit;
  end;
  ImageBackground.Align := alClient;
  Form1.DoubleBuffered := True;
  ConfigLoad;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  ConfigSave;
end;

procedure TForm1.BtnAddClick(Sender: TObject);
var
  NewMAC, NewName : String;
  NewRow: TListItem;
const
  DEFAULT_MAC = '00-00-00-00-00-00';
begin
  NewMAC := InputBox( 'Add a computer', 'Please enter a MAC adress:', DEFAULT_MAC );
  NewMAC := Trim(NewMAC);
  if ( ( NewMAC = '' ) or ( NewMAC = DEFAULT_MAC ) ) then Exit;
  if ( Length( NewMAC ) <> 17 ) then
  begin
    MessageBoxA( Handle, PChar('Mac adress is not valid!'), PChar('Incorrect'), MB_ICONWARNING );
    Exit;
  end;

  NewName := InputBox( 'Add a computer', 'Please enter a computer name:', '');
  NewName := Trim(NewName);
  if NewName = '' then NewName := NewMAC;

  NewRow := ListMAC.Items.Add;
  NewRow.Caption := NewName;
  NewRow.SubItems.Add(NewMAC);

  ConfigSave;
end;

procedure TForm1.BtnRemoveClick(Sender: TObject);
begin
  if ( ListMAC.ItemIndex < 0 ) then
  begin
    MessageBoxA( Handle, PChar('Please select an item before delete it!'), PChar('Warning'), MB_ICONWARNING );
    Exit;
  end;
  ListMAC.Items.Delete( ListMAC.ItemIndex );
  ConfigSave;
end;



end.

