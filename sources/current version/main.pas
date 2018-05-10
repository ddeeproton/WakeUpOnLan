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
  if not FileExists('NameList.txt') then MessageBoxA( Handle, PChar('Attention : Un problème empêche de sauvegarder la liste.'), PChar('Incorrect'), MB_ICONERROR );
  // Save Mac
  data := TStringList.Create;
  for i := 0 to ListMAC.Items.Count -1 do
    data.Add(ListMAC.Items.Item[i].SubItems[0]);
  if data.Count = 0 then Exit;
  FilesManager.WriteStringListInFile('MacList.txt', data);
  if not FileExists('MacList.txt') then MessageBoxA( Handle, PChar('Attention : Un problème empêche de sauvegarder la liste.'), PChar('Incorrect'), MB_ICONERROR );
end;

procedure TForm1.BtnWakeupClick(Sender: TObject);
var
  Cmpt : Integer;   // Compteur
begin

  if ( ListMAC.Items.Count = 0 ) then   // Verifie que la liste ne soit pas vide
  begin
    MessageBoxA( Handle, PChar('Ajoutez d''abord des adresses MAC dans la liste !'), PChar('Stop'), MB_ICONWARNING );
    Exit;
  end;

  BtnWakeup.Enabled := False;   // On désactive bouton Wake Up

  for Cmpt := 0 to ( ListMAC.Items.Count - 1 ) do // Parcour la liste des adresses MAC
  begin
    //ShowMessage(ListMAC.Items.Item[Cmpt].SubItems[0]);
    GoWOL( ListMAC.Items.Item[Cmpt].SubItems[0] );   // On demande le reveille de la machine
    Sleep( 1500 );                          // Attente pour eviter les collisions
  end;

  //Caption := Application.Title;   // Renomme la page
  BtnWakeup.Enabled := True;      // On résactive bouton Wake Up

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

  NewMAC := InputBox( 'Ajouter', 'Entrez une adresse MAC :', DEFAULT_MAC );   // Saisie de l'adresse
  NewMAC := Trim( NewMAC );   // On trim pour éviter les erreurs

  if ( ( NewMAC = '' ) or ( NewMAC = DEFAULT_MAC ) ) then Exit;

  // Verification de longeure
  // ( je vous laisse ajouter les controles sur les valeurs etc..)
  if ( Length( NewMAC ) <> 17 ) then
  begin
    MessageBoxA( Handle, PChar('L''adresse MAC que vous avez entré est incorrect !'), PChar('Incorrect'), MB_ICONWARNING );
    Exit;
  end;

  NewName := InputBox( 'Ajouter', 'Entrez un nom :', '');
  NewName := Trim( NewName );
  if NewName = '' then NewName := NewMAC;

  NewRow := ListMAC.Items.Add;
  NewRow.Caption := NewName;
  NewRow.SubItems.Add(NewMAC);

  ConfigSave;
end;

procedure TForm1.BtnRemoveClick(Sender: TObject);
begin

    // Verifie qu'un élément soit séléctionné
    if ( ListMAC.ItemIndex < 0 ) then
    begin
      MessageBoxA( Handle, PChar('Selectionnez une adresse dans la liste avant !'), PChar('Attention'), MB_ICONWARNING );
      Exit;
    end;

    ListMAC.Items.Delete( ListMAC.ItemIndex );  // On supprime de la liste

    ConfigSave;
end;



end.

