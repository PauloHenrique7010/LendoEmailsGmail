program leremail;

uses
  Vcl.Forms,
  PrincipalForm in 'PrincipalForm.pas' {PrincipalFrm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TPrincipalFrm, PrincipalFrm);
  Application.Run;
end.
