program XpresI;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, synhighlighterfacil, utileditsyn, syncompletionq, FormPrincipal,
  uXpres, XpresComplet, Globales, XpresBas, formconfig, FrameCfgEdit, FormOut
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.CreateForm(TfrmPrincipal, frmPrincipal);
  Application.CreateForm(TConfig, Config);
  Application.CreateForm(TfrmOut, frmOut);
  Application.Run;
end.

