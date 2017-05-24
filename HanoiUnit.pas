unit HanoiUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, GLWin32Viewer, GLCrossPlatform, BaseClasses, GLScene,
  GLObjects, GLCoordinates, GLGeomObjects, GLContext, XPMan, StdCtrls,
  Buttons, Spin, GLSpaceText, GLMaterial, GLCelShader, GLBlur,
  GLShadowVolume, GLCadencer;

type
  TForm1 = class(TForm)
    InterfacePanel: TPanel;
    GLViewer: TGLSceneViewer;
    Play: TBitBtn;
    Tu: TComboBox;
    TimerChangeCyl: TTimer;
    XPMan: TXPManifest;
    Timer1: TTimer;
    GLScene: TGLScene;
    Light: TGLLightSource;
    GLCamera: TGLCamera;
    Objects: TGLDummyCube;
    MainClndr: TGLCylinder;
    Cube1: TGLCube;
    Point000: TGLPoints;
    Cube2: TGLCube;
    Cube3: TGLCube;
    Text2: TGLSpaceText;
    Text3: TGLSpaceText;
    GLMaterial: TGLMaterialLibrary;
    Text1: TGLSpaceText;
    GLCelTexShader: TGLCelShader;
    GLCelColShader: TGLCelShader;
    CylN: TComboBox;
    GLCadencer1: TGLCadencer;
    procedure Timer1Timer(Sender: TObject);
    procedure PlayClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure CylNChange(Sender: TObject);
    procedure TimerChangeCylTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure GLCadencer1Progress(Sender: TObject; const deltaTime,
      newTime: Double);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure EnabledInterface(Bool: Boolean);
  end;

  TCylArray = array of TGLCylinder;
  TMove = object
//    Obj: TGLCylinder;
    From, Tu: Integer;
  end;

const
  MaxN = 7;

var
  Form1: TForm1;
  Tower: array[1..3] of TCylArray;
//  RainbowColors: array[0..6] of TColor = (clRed, $001780F8, clYellow, clGreen,
//    $00FFFF00, clBlue, clPurple);
  TowersPos: array[1..3] of Extended;
  CurrentTower: Integer = 1;
  TowerArchive: TCylArray;
  OldN: Integer = MaxN;

var
  PosX, PosY, XShift, DeltaX, MaxY, NewX, NewY: Extended;
  X1, Y1, X2, Y2, X0, A: Extended;
  Obj: TGLCylinder;
  GoNext: Boolean = True;
  StackTower: array of TMove;
  CurrStack: Integer = 0;

implementation

uses Math;

{$R *.dfm}

procedure Hanoi(N, From, Tu, Buff: Integer);
begin
  if N > 1 then
    Hanoi(N - 1, From, Buff, Tu);
  SetLength(StackTower, High(StackTower) + 2);
  StackTower[High(StackTower)].From := From;
  StackTower[High(StackTower)].Tu := Tu;
  if N > 1 then
    Hanoi(N - 1, Buff, Tu, From);
end;


procedure TForm1.Timer1Timer(Sender: TObject);
var
  I: Longint;
begin

//  GLScene.CurrentBuffer.AntiAliasing := aa4xHQ

  SetLength(Tower[1], MaxN);
  for I := 0 to High(Tower[1]) do begin
    Tower[1, I] := TGLCylinder.CreateAsChild(Objects);
    with Tower[1, I] do begin
      Assign(MainClndr);
      Position.Z := 0;
      Position.Y := Position.Y + I * Height;
      TopRadius := 0.1 * (8 - I);
      BottomRadius := TopRadius;
 //     Material.FrontProperties.Diffuse.AsWinColor := RainbowColors[I];
      Material.LibMaterialName := 'Disk' + IntToStr(I + 1);
//      GLShadow.Occluders.AddCaster(Tower[1, I]);
    end;
  end;

  TowersPos[1] := Cube1.Position.X;
  TowersPos[2] := Cube2.Position.X;
  TowersPos[3] := Cube3.Position.X;

  Timer1.Enabled := False;
end;

function Spare(A, B: Integer): Integer;
var
  I: Integer;
begin
  for I := 1 to 3 do
    if (I <> A) and (I <> B) then begin
      Result := I;
      Exit;
    end;
end;

procedure TForm1.PlayClick(Sender: TObject);
var
  I, Buff: Longint;
begin
  EnabledInterface(False);

  Buff := Spare(CurrentTower, StrToInt(Tu.Items[Tu.ItemIndex][4]));
  Hanoi(CylN.ItemIndex + 1, CurrentTower, StrToInt(Tu.Items[Tu.ItemIndex][4]), Buff);
  GLCadencer1.Enabled := True;

end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Halt;
end;

procedure TForm1.EnabledInterface(Bool: Boolean);
begin
  InterfacePanel.Enabled := Bool;
  Play.Enabled := Bool;
  CylN.Enabled := Bool;
  Tu.Enabled := Bool;
end;

procedure TForm1.CylNChange(Sender: TObject);
begin
  Play.Enabled := False;
  TimerChangeCyl.Enabled := False;
  TimerChangeCyl.Enabled := True;
end;



procedure TForm1.TimerChangeCylTimer(Sender: TObject);
var
  TmpTower, TmpTower2: ^TCylArray;
  Diff, I: Integer;
  Tm, OldTm, TimeShift: TTime;
  YShift: Extended;
begin
  TimerChangeCyl.Enabled := False;
  if (CylN.ItemIndex + 1) = OldN then begin
    Play.Enabled := True;
    Exit;
  end;
  OldN := CylN.ItemIndex + 1;
  Play.Enabled := False;

  Diff := High(Tower[CurrentTower]) - (CylN.ItemIndex + 1) + 1;

  if Diff > 0 then begin
    TmpTower := @Tower[CurrentTower];
    TmpTower2 :=@TowerArchive;
  end else begin
    TmpTower := @TowerArchive;
    TmpTower2 := @Tower[CurrentTower];
  end;

  YShift := 7 * Sign(Diff);
  OldTm := GetTime;
  repeat
    Tm := GetTime;
    TimeShift := Abs(Tm - OldTm) * 100000;
    OldTm := Tm;
    if TimeShift > 0.1 then
      TimeShift := 0.001;
    for I := High(TmpTower^) - Abs(Diff) + 1 to High(TmpTower^) do begin
      TmpTower^[I].Visible := True;
      TmpTower^[I].Position.Y := TmpTower^[I].Position.Y + TimeShift * YShift * TmpTower^[High(TmpTower^)].Position.Y;
      TmpTower^[I].Position.X := Tower[CurrentTower, 0].Position.X;
    end;
    Application.ProcessMessages;
  until ((Diff > 0) and (TmpTower^[High(TmpTower^)].Position.Y > 6)) or
    ((Diff < 0) and (TmpTower^[High(TmpTower^)].Position.Y <= MainClndr.Position.Y + MainClndr.Height * (High(Tower[CurrentTower]) + 1)));

  for I := High(TmpTower^) downto High(TmpTower^) - Abs(Diff) + 1 do begin
    SetLength(TmpTower2^, High(TmpTower2^) + 2);
    TmpTower2^[High(TmpTower2^)] := TmpTower^[I];
  end;

  SetLength(TmpTower^, High(TmpTower^) - Abs(Diff) + 1);

  for I := 0 to High(TowerArchive) do begin
    TowerArchive[I].Position.Y := 6 + MainClndr.Position.Y + (7 - I) * MainClndr.Height;
    TowerArchive[I].Visible := False;
  end;

  for I := 0 to High(Tower[CurrentTower]) do begin
    Tower[CurrentTower, I].Position.Y := MainClndr.Position.Y + I * MainClndr.Height;
  end;

  Play.Enabled := True;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  DoubleBuffered := True;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  GLCamera.SceneScale := GLViewer.Width / 830;
end;

procedure TForm1.GLCadencer1Progress(Sender: TObject; const deltaTime,
  newTime: Double);

var
  Tu, From, I: Integer;

procedure Swap(var A, B: Extended);
var
  C: Extended;
begin
  C := A;
  A := B;
  B := C;
end;

begin

  if GoNext then begin
    From := StackTower[CurrStack].From;
    Tu := StackTower[CurrStack].Tu;

    SetLength(Tower[Tu], High(Tower[Tu]) + 2);
    Tower[Tu, High(Tower[Tu])] := Tower[From, High(Tower[From])];
    SetLength(Tower[From], High(Tower[From]));

    Obj := Tower[Tu, High(Tower[Tu])];
    NewX := TowersPos[Tu];
    NewY := Form1.MainClndr.Position.Y + Form1.MainClndr.Height * High(Tower[Tu]);

    GoNext := False;

    with Obj.Position do begin
      PosX := X;
      PosY := Y;
      DeltaX := NewX - X;

      MaxY := Form1.MainClndr.Height * (Form1.CylN.ItemIndex + 1) + 0.7;

      X1 := PosX;
      Y1 := MaxY - PosY;
      X2 := NewX;
      Y2 := MaxY - NewY;
      if PosX > NewX then begin
        Swap(X1, X2);
        Swap(Y1, Y2);
      end;

      X0 := (X1 * Sqrt(Y2) + X2 * Sqrt(Y1)) / (Sqrt(Y1) + Sqrt(Y2));
      A := (X0 - X1) / Sqrt(Y1);
    end;

  end;

  with Obj.Position do begin
      XShift := deltaTime * Sign(DeltaX) * 4;

      PosX := PosX + XShift;
      PosY := MaxY - Sqr((X0 - PosX)/A);

      X := PosX;
      Y := PosY;

    if Abs(PosX - NewX) <= Abs(XShift) then begin
      X := NewX;
      Y := NewY;
      GoNext := True;
      Inc(CurrStack);
      if CurrStack > High(StackTower) then begin
        GLCadencer1.Enabled  := False;
        CurrStack := 0;
        SetLength(StackTower, 0);

        CurrentTower := StrToInt(Form1.Tu.Items[Form1.Tu.ItemIndex][4]);

        Form1.Tu.Clear;
        for I := 1 to 3 do
          if I <> CurrentTower then
            Form1.Tu.Items.Add('to ' + IntToStr(I));
        Form1.Tu.ItemIndex := 0;
        EnabledInterface(True);
      end;
    end;

  end;


end;

end.
