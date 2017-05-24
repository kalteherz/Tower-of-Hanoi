program HanoiTower;

uses
  Forms,
  HanoiUnit in 'HanoiUnit.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Hanoi tower';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
