{
  ElgMAC.Pas
  ---------------------------------------------------------

    MORPHEE : Implémentation d'un "Wake On LAN"
    Par :
      LEVEUGLE Damien
      fOxy [ http://www.delphifr.com/auteurdetail.aspx?ID=360948 ]

    ElGuevel (c) 2006
    Elguevel@Free.Fr

  ---------------------------------------------------------
   Unité de gestion des adresses MAC
  ---------------------------------------------------------
}

unit ElgMAC;

interface

uses Windows, Winsock, Classes;

type
  TAdresseMac = Array[0..5]   of Byte;
  TMagicPack  = Array[0..101] of Byte;

function SendARP( const DestIP: DWORD; const SrcIP: DWORD; const pMacAddr: PULONG; const PhyAddrLen: PULONG ): DWord; stdcall; external 'IPHLPAPI.DLL';

function  MacToStr(const MacAddress : TAdresseMac; const Delimiter : char = '-') : string;
function  DeleteChar(const S : string; const CharToRemove : char) : string;
function  StrToMac(var MacAddress : TAdresseMac; const MacStr : string; const Delimiter : char = '-') : Boolean;
procedure MagicPackToStrings(const MagicPack : TMagicPack; Strings : TStrings);
procedure CreateMagicPack(const MacAddress : TAdresseMac; var MagicPack : TMagicPack);
function  IPToMAC( AdresseIP : string ) : string;

implementation

// Adresse mac vers chaine
function MacToStr(const MacAddress : TAdresseMac; const Delimiter : char = '-') : string;
var
  PResult : PChar;
  i       : integer;

const
  Digits : array[0..15] of Char = '0123456789abcdef';

begin
  // une adresse MAC fait 17 caracteres de long
  SetLength( Result, 17 );
  PResult := PChar( Result );

  for I := 0 to 5 do
  begin
      // on convertis l'octet en texte
      PResult[0] := Digits[MacAddress[I] shr 4];
      PResult[1] := Digits[MacAddress[I] and $F];
      // on ajoute un delimiteur ou non
      if ( i < 5 ) then
      begin
         PResult[2] := Delimiter;
         Inc( PResult, 3 );
      end else
         Inc( PResult, 2 );
  end;
  
end;

// Interne, supprime le caractere 'chartoremove' de la chaine 's'
function DeleteChar(const S : string; const CharToRemove : char) : string;
var
  pR : PChar;
  L  : Integer;
  I  : integer;
begin
  SetLength( Result, length(S) );
  pR := PChar( Result );
  L  := 0;
  for i := 1 to Length(S) do
    if ( s[i] <> CharToRemove ) then
    begin
       pR[0] := s[i];
       Inc( pR);
       Inc( L );
    end;
  SetLength( Result, L );
end;

// transforme une chaine representant une adresse MAC (ff-aa-cc-dd-ee-56) vers un TMacAddress
function StrToMac(var MacAddress : TAdresseMac; const MacStr : string; const Delimiter : char = '-') : Boolean;
var
    i : integer;
    S : string;
    b1 : Byte;
    b2 : Byte;
begin
  // on supprime le delimiteur
  S := DeleteChar( MacStr, Delimiter );
  // si la longeur est differente de 12 c'est qu'il y a un probleme
  if Length(S) <> 12 then
    Result := False
  else
  begin
    for i := 0 to 5 do
    begin
      // on recupère la valeur ordinal du caractere et on decremente pour obtenir une valeur entre 0 et 15
      // shl 1 = *2 , un decalage est plus rapide qu'une multiplication
      b1 := Ord( s[(i shl 1) + 1] ) - 48;
      b2 := Ord( s[(i shl 1) + 2] ) - 48;
      if b1 > 15 then dec( b1, 39 );
      if b2 > 15 then dec( b2, 39 );

      MacAddress[i] := ( b1 shl 4 ) + ( b2 and $F );
    end;
    Result := True;
  end;
end;


// convertis un MagicPack vers une liste de chaines
procedure MagicPackToStrings(const MagicPack : TMagicPack; Strings : TStrings);
var
  I  : integer;
  MA : TAdresseMac;
begin
  Strings.BeginUpdate;
  for I := 0 to 16 do
  begin
      // on copie directement 6 octets de la memoire a partir de l'index i*6 dans MA
      Move( MagicPack[I*6], MA, 6 );
      // puis on utilise MacToStr pour convertir la chaine
      Strings.Add( MacToStr(MA, ' ') );
  end;
  Strings.EndUpdate;
end;


// cree un MagicPack a partir d'une adresse MAC (TMacAddress)
procedure CreateMagicPack(const MacAddress : TAdresseMac; var MagicPack : TMagicPack);
var
  I : integer;
begin
  // on remplis les 6 premier octets avec $FF
  for i := 0 to 5 do
      MagicPack[i] := $FF;

  // on copie 16 fois les 6 octets de MacAddress dans MagicPack a l'index i*6
  for i := 1 to 16 do
      Move(MacAddress, MagicPack[i*6], 6);
end;

{ Renvoi l'adresse MAC correspondante à l'adresse IP }
function IPToMAC( AdresseIP : string ) : string;
var
  ip     : DWORD;
  mac    : TAdresseMac;
  maclen : Integer;
begin
  ip      := inet_addr( PChar(AdresseIP) );
  maclen  := SizeOf(TAdresseMac);
  SendArp ( ip, 0, @MAC, @maclen );
  Result  := MacToStr( MAC );
end;

end.
