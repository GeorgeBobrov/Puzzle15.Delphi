unit uFormPuzzle15;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Objects, FMX.Effects, FMX.Filter.Effects, FMX.Ani, Math,
  FMX.Controls.Presentation;

type
  TFormPuzzle15 = class(TForm)
    PanelClient: TPanel;
    Tile1: TRectangle;
    TileText: TText;
    TileGradientAni: TGradientAnimation;
    PanelMenuCl: TRectangle;
    MenuFloatAnimation: TFloatAnimation;
    GridPanelLayout1: TGridPanelLayout;
    Button3x3: TRectangle;
    Text33: TText;
    TimerCreateTiles: TTimer;
    ColorAnimation33: TColorAnimation;
    ColorAnimation4: TColorAnimation;
    Button4x4: TRectangle;
    Text44: TText;
    ColorAnimation5: TColorAnimation;
    ColorAnimation6: TColorAnimation;
    Button5x5: TRectangle;
    Text55: TText;
    ColorAnimation55: TColorAnimation;
    ColorAnimation3: TColorAnimation;
    ButtonClose: TRectangle;
    ButtonCloseColorAni: TColorAnimation;
    CloseGloomEffect: TGloomEffect;
    CloseGloomEffectAni: TFloatAnimation;
    ImageClose: TImage;
    PanelTop: TRectangle;
    LayoutCenter: TLayout;
    ButtonShuffle: TRectangle;
    ImageShuffle: TImage;
    ShuffleColorAnimation: TColorAnimation;
    ShuffleGloomEffect: TGloomEffect;
    ShuffleGloomEffectAni: TFloatAnimation;
    ButtonMenu: TRectangle;
    ImageMenu: TImage;
    ColorAnimation2: TColorAnimation;
    GloomEffect4: TGloomEffect;
    FloatAnimation4: TFloatAnimation;
    PanelTime: TRectangle;
    TextTime: TText;
    TimerReShuffle: TTimer;
    TimerResize: TTimer;
    TimerTime: TTimer;
    ButtonDisappeare: TButton;
    ButtonPlace: TButton;
    PanelDebug: TPanel;
    ButtonTimeRunningOut: TButton;
    ButtonBaseNotChanged: TButton;
    TimerClose: TTimer;
    ButtonPuzzleMatched: TButton;
    ButtonTimeOver: TButton;
    CheckBoxPl1: TCheckBox;
    SpeedButtonEffects: TSpeedButton;
    procedure CreateTiles;
    procedure ButtonMenuClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ButtonChangeBaseClick(Sender: TObject);
    procedure TimerCreateTilesTimer(Sender: TObject);
    procedure ButtonDisappeareClick(Sender: TObject);
    procedure ButtonPlaceClick(Sender: TObject);
    procedure ButtonShuffleClick(Sender: TObject);
    procedure TimerReShuffleTimer(Sender: TObject);
    procedure TileMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure PanelClientResize(Sender: TObject);
    procedure TimerResizeTimer(Sender: TObject);
    procedure TimerTimeTimer(Sender: TObject);
    procedure ButtonTimeRunningOutClick(Sender: TObject);
    procedure ButtonCloseClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ButtonBaseNotChangedClick(Sender: TObject);
    procedure TimerCloseTimer(Sender: TObject);
    procedure ButtonPuzzleMatchedClick(Sender: TObject);
    procedure ButtonTimeOverClick(Sender: TObject);
    procedure SpeedButtonEffectsClick(Sender: TObject);
    type
      TMode = (Game, GameOver, JustShuffled, PuzzleMatched);
  private
    { Private declarations }
    FMode: TMode;
    FBase: integer;
    procedure SetMode(const Value: TMode);
    procedure SetMaxTime;
    procedure SetBase(const Value: integer);
  public
    { Public declarations }
    Tiles: array of TRectangle;

    TileSize: integer;
    TileSpacing: integer;
    SpaceX, SpaceY: integer;
    TileFillNormalColor, TileFillNormalColor1: TColor;
    LastResizeTime: TDateTime;
    ClosingAnimation: Boolean;
    WaitAnimationEnd: Boolean;

    property Base: integer read FBase write SetBase;
    property Mode: TMode read FMode write SetMode;

    function TryMoveTile(TilePosition: integer; MoveAniDuration: single): Boolean;
    procedure AnimateMoveTile(ATile: TRectangle; MoveAniDuration: single);

    function CheckCanPuzzleMatch: Boolean;
    procedure CheckPuzzleMatched;

    procedure CalcConsts;

    procedure AnimatePlaceTilesFast;
    procedure AnimatePlaceTilesSlow;
    procedure AnimateTilesDisappeare;
    procedure AnimatePrepareBeforePlace;
    procedure AnimateBaseNotChanged;
    procedure AnimateTimeRunningOut;
    procedure AnimatePuzzleMatched;
    procedure AnimateTimeOver;
    procedure AnimateNormalizeTilesColor;
    procedure StartBlinkShuffle;
    procedure StopBlinkShuffle;
  end;

var
  FormPuzzle15: TFormPuzzle15;

implementation

{$R *.fmx}
{$R *.LgXhdpiPh.fmx ANDROID}
{$R *.Windows.fmx MSWINDOWS}

const
  MaxMoveAniDuration = 0.15;
  MinMoveAniDuration = 0.001;


procedure TFormPuzzle15.FormCreate(Sender: TObject);
begin
{$IF defined(MSWINDOWS) or defined(OSX) or defined(LINUX)}
   PanelClient.OnResize := PanelClientResize;
{$ENDIF}

  TileFillNormalColor := Tile1.Fill.Gradient.InterpolateColor(0);
  TileFillNormalColor1 := Tile1.Fill.Gradient.InterpolateColor(1);

  Base := 4;
end;






procedure TFormPuzzle15.SetMode(const Value: TMode);
begin
  FMode := Value;
  TimerTime.Enabled := (FMode = Game);
end;







procedure TFormPuzzle15.ButtonChangeBaseClick(Sender: TObject);
begin
  Base := (Sender as TRectangle).Tag;
end;


procedure TFormPuzzle15.SetBase(const Value: integer);
var
  i : Integer;
begin
  if (Value = Base) then
  begin
    AnimateBaseNotChanged;

    exit;
  end;

  Mode := GameOver;
  AnimateTilesDisappeare;

  FBase := Value;
  SetMaxTime;

  if Length(Tiles) > 0 then
    TimerCreateTiles.Interval := (520 + 30 * Length(Tiles)) {$IF defined(ANDROID)} * 2  {$ENDIF}
  else
    TimerCreateTiles.Interval := 50;
  TimerCreateTiles.Enabled := true;
end;




procedure TFormPuzzle15.TimerCreateTilesTimer(Sender: TObject);
var
  i : Integer;
begin
  TimerCreateTiles.Enabled := false;
  CreateTiles;

  AnimatePrepareBeforePlace;
  AnimatePlaceTilesFast;
end;


procedure TFormPuzzle15.CreateTiles;
var
  i : Integer;
  NewTile: TRectangle;
begin

//  Tile1.Position.X := Self.Width - Tile1.Width - 10;
//  Tile1.Position.Y := Self.Height - Tile1.Height - 10;
  Tile1.Tag := 0;          //Position of Tile in flat array, see ind()
  Tile1.TagFloat := 0;     //Actual number of Tile

  Tile1.Opacity := 0;
  Tile1.Visible := true;


  for i := 0 to Length(Tiles) - 1 do
    if (Tiles[i] <> nil) then
      if (Tiles[i] = Tile1) then
        Tiles[i] := nil
      else
        FreeAndNil(Tiles[i]);


  SetLength(Tiles, Base * Base);
  Tiles[0] := Tile1;


  for i := 1 to Length(Tiles) - 2 do
    if (Tiles[i] = nil) then
    begin
      NewTile := TRectangle(Tile1.Clone(Self));

      NewTile.OnMouseDown := TileMouseDown;
      (NewTile.Children[0] as TText).Text := IntToStr(i + 1);
      (NewTile.Children[1] as TGradientAnimation).StartValue.Assign(NewTile.Fill.Gradient);
      (NewTile.Children[1] as TGradientAnimation).StopValue.Assign(NewTile.Fill.Gradient);
//      (NewTile.Children[1] as TGradientAnimation).OnFinish := RecGradientAniFinish;

      NewTile.TagFloat := i;


//      NewTile.Position.X := Tile1.Position.X;
//      NewTile.Position.Y := Tile1.Position.Y;
//      NewTile.Opacity := 1;
      NewTile.Parent := PanelClient;
      NewTile.SendToBack;

      Tiles[i] := NewTile;
    end;

  if (Tiles[Length(Tiles) - 1] <> nil) then
    Tiles[Length(Tiles) - 1] := nil;


end;













function ind(Row, Col: Integer): Integer; inline;
begin
  Result := Row * FormPuzzle15.Base + Col;
end;



procedure TFormPuzzle15.TileMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
var
  SenderTile: TRectangle absolute Sender;
  WasMoved: Boolean;
begin
  if (Mode = JustShuffled) then
    Mode := Game;

  WasMoved := TryMoveTile(SenderTile.Tag, MaxMoveAniDuration);

  if WasMoved then
    CheckPuzzleMatched;
end;


function TFormPuzzle15.TryMoveTile(TilePosition: integer; MoveAniDuration: single): Boolean;
var
  RowPressed, ColPressed: Word;
  Row, Col, RowNoTile, ColNoTile, RowToMove, ColToMove: integer;
  WasMoved: Boolean;
  NewPosition: integer;
begin
  DivMod(TilePosition, Base, RowPressed, ColPressed);

  WasMoved := false;
  for Row := 0 to Base - 1 do
    if (Tiles[ind(Row, ColPressed)] = nil) then
    begin
      RowNoTile := Row;

      if (RowNoTile > RowPressed) then
        for RowToMove := RowNoTile - 1 downto RowPressed do
        begin
          NewPosition := ind(RowToMove + 1 , ColPressed);
          Tiles[NewPosition] := Tiles[ind(RowToMove , ColPressed)];
          Tiles[NewPosition].Tag := NewPosition;
          Tiles[ind(RowToMove , ColPressed)] := nil;

          AnimateMoveTile(Tiles[NewPosition], MoveAniDuration);

          WasMoved := true;
        end;

      if (RowPressed > RowNoTile) then
        for RowToMove := RowNoTile + 1 to RowPressed do
        begin
          NewPosition := ind(RowToMove - 1 , ColPressed);
          Tiles[NewPosition] := Tiles[ind(RowToMove , ColPressed)];
          Tiles[NewPosition].Tag := NewPosition;
          Tiles[ind(RowToMove , ColPressed)] := nil;

          AnimateMoveTile(Tiles[NewPosition], MoveAniDuration);

          WasMoved := true;
        end;

    end;

  if not WasMoved then
  for Col := 0 to Base - 1 do
    if (Tiles[ind(RowPressed , Col)] = nil) then
    begin
      ColNoTile := Col;

      if (ColNoTile > ColPressed) then
        for ColToMove := ColNoTile - 1 downto ColPressed do
        begin
          NewPosition := ind(RowPressed , ColToMove + 1);
          Tiles[NewPosition] := Tiles[ind(RowPressed , ColToMove)];
          Tiles[NewPosition].Tag := NewPosition;
          Tiles[ind(RowPressed , ColToMove)] := nil;

          AnimateMoveTile(Tiles[NewPosition], MoveAniDuration);

          WasMoved := true;
        end;

      if (ColPressed > ColNoTile) then
        for ColToMove := ColNoTile + 1 to ColPressed do
        begin
          NewPosition := ind(RowPressed , ColToMove - 1);
          Tiles[NewPosition] := Tiles[ind(RowPressed , ColToMove)];
          Tiles[NewPosition].Tag := NewPosition;
          Tiles[ind(RowPressed , ColToMove)] := nil;

          AnimateMoveTile(Tiles[NewPosition], MoveAniDuration);

          WasMoved := true;
        end;

    end;

  Result := WasMoved;
end;


procedure TFormPuzzle15.AnimateMoveTile(ATile: TRectangle; MoveAniDuration: single);
var
  NewRow, NewCol: Word;
  X, Y : Integer;
  Duration: single;
begin
  DivMod(ATile.Tag, Base, NewRow, NewCol);

  X := SpaceX + Round(NewCol * (ATile.Width * ATile.Scale.X + TileSpacing));
  Y := SpaceY + Round(NewRow * (ATile.Height * ATile.Scale.Y + TileSpacing));

  if MoveAniDuration > 0 then
  begin
    ATile.AnimateFloatDelay('Position.X', X,
      MoveAniDuration, 0, TAnimationType.Out, TInterpolationType.Exponential);

    if WaitAnimationEnd then
      ATile.AnimateFloatWait('Position.Y', Y,
        MoveAniDuration, TAnimationType.Out, TInterpolationType.Exponential)
    else
      ATile.AnimateFloatDelay('Position.Y', Y,
        MoveAniDuration, 0, TAnimationType.Out, TInterpolationType.Exponential);
  end
  else
  begin
    ATile.Position.X := X;
    ATile.Position.Y := Y;
  end;

end;



procedure TFormPuzzle15.CheckPuzzleMatched;
var
  i : Integer;
  LPuzzleMatched: Boolean;
begin
  LPuzzleMatched := true;
  for i := 0 to Length(Tiles) - 1 do
    if (Tiles[i] <> nil) then
      if (Tiles[i].TagFloat <> Tiles[i].Tag) then
      begin
        LPuzzleMatched := false;
        Break;
      end;

  if LPuzzleMatched and (Mode = Game) then
  begin
    Mode := PuzzleMatched;

    AnimatePuzzleMatched;
  end;


  if (not LPuzzleMatched) and ((Mode = PuzzleMatched) or (Mode = JustShuffled)) then
  begin
    AnimateNormalizeTilesColor;

    if (Mode = PuzzleMatched) then
      Mode := GameOver;
  end;

end;















procedure TFormPuzzle15.ButtonShuffleClick(Sender: TObject);
var
  TilesOld: array of TRectangle;
  i, NewI : Integer;
  NewRow, NewCol: Word;
  X, Y : Integer;
  MoveCount: Integer;
  MoveAniDuration: Single;
begin
//  SetLength(TilesOld, Length(Tiles));
//  for i := 0 to Length(Tiles) - 1 do
//  begin
//    TilesOld[i] := Tiles[i];
//    Tiles[i] := nil;
//  end;
//
//  for i := 0 to Length(Tiles) - 1 do
//    if (TilesOld[i] <> nil) then
//    repeat
//      newI := Random(Length(Tiles));
//      if (Tiles[NewI] = nil) then
//      begin
//        Tiles[NewI] := TilesOld[i];
//        Tiles[NewI].Tag := NewI;
//        Break;
//      end;
//
//    until false;
//
//
//  for i := 0 to Length(Tiles) - 1 do
//    if (Tiles[i] <> nil) then
//    begin
//      DivMod(Tiles[i].Tag, Base, NewRow, NewCol);
//
//      X := SpaceX + Round(NewCol * (Tiles[i].Width * Tiles[i].Scale.X + TileSpacing));
//      Y := SpaceY + Round(NewRow * (Tiles[i].Height * Tiles[i].Scale.Y + TileSpacing));
//
//      Tiles[i].AnimateFloatDelay('Position.X', X,
//        0.4, 0, TAnimationType.Out, TInterpolationType.Exponential );
//      Tiles[i].AnimateFloatDelay('Position.Y', Y,
//        0.4, 0.01 * i, TAnimationType.Out, TInterpolationType.Exponential );
//    end;

  WaitAnimationEnd := true;
  MoveCount := Length(Tiles) * Length(Tiles);
  for i := 1 to MoveCount do
  begin
    if i <= 10 then
      MoveAniDuration := MinMoveAniDuration + (MaxMoveAniDuration *
        (1 - (i / 10)));

    if i >= MoveCount - 10 then
      MoveAniDuration := MinMoveAniDuration + (MaxMoveAniDuration *
        (1 - ((MoveCount - i) / 10)));

    if (i > 20) and (i < MoveCount - 20) then
      if (i mod 10) = 0 then
        MoveAniDuration := MinMoveAniDuration
      else
        MoveAniDuration := 0;

    repeat
      newI := Random(Length(Tiles));
    until TryMoveTile(newI, MoveAniDuration);
  end;
  WaitAnimationEnd := false;


  SetMaxTime;

  StopBlinkShuffle;

//  if not CheckCanPuzzleMatch then
//  begin
//    TimerReShuffle.Interval := 400 + 10 * Length(Tiles);
//    TimerReShuffle.Enabled := true;
//    exit;
//  end;


  Mode := JustShuffled;

  CheckPuzzleMatched;
end;




function TFormPuzzle15.CheckCanPuzzleMatch: Boolean;
var
  i, j: Integer;
  iValue, jValue: Integer;
  inv: Integer;
begin
  inv := 0;
  for i := 0 to Length(Tiles) - 1 do
    if (Tiles[i] <> nil) then
      for j := 0 to i - 1 do
      begin
        iValue := Tiles[i].Tag + 1;
        if (Tiles[j] = nil) then
          jValue := 0
        else
          jValue := Tiles[j].Tag + 1;
        if (jValue > iValue) then
          Inc(inv);
      end;
  for i := 0 to Length(Tiles) - 1 do
    if (Tiles[i] = nil) then
      Inc(inv, (i div Base) + 1);

  Result := not Odd(inv);
end;



procedure TFormPuzzle15.StartBlinkShuffle;
begin
  ShuffleGloomEffect.BaseIntensity := 1;
  ShuffleGloomEffect.BaseSaturation := 1;
  ShuffleGloomEffect.GloomIntensity := 0;
  ShuffleGloomEffect.GloomSaturation := 0;
  //    ShuffleGloomEffect.Enabled := false;
  ShuffleGloomEffectAni.Enabled := true;
end;

procedure TFormPuzzle15.StopBlinkShuffle;
begin
  ShuffleGloomEffectAni.Enabled := false;
  //  ShuffleGloomEffect.Enabled := true;
  ShuffleGloomEffect.BaseIntensity := 0.5;
  ShuffleGloomEffect.BaseSaturation := 0.5;
  ShuffleGloomEffect.GloomIntensity := 0.5;
  ShuffleGloomEffect.GloomSaturation := 0.05;
end;

procedure TFormPuzzle15.SetMaxTime;
var
  Sec, Min: Word;
begin
  TextTime.Tag := ((Base * Base * Base * Base) div 20) * 10;
  DivMod(TextTime.Tag, 60, Min, Sec);
  TextTime.Text := Format('%d:%.2d', [Min, Sec]);
end;


procedure TFormPuzzle15.TimerReShuffleTimer(Sender: TObject);
begin
  TimerReShuffle.Enabled := false;
  ButtonShuffleClick(TimerReShuffle);
end;


procedure TFormPuzzle15.PanelClientResize(Sender: TObject);
var Hour, Min, Sec, MSec: Word;
begin
  DecodeTime(Time - LastResizeTime, Hour, Min, Sec, MSec);
  if (Sec * 1000 + MSec < 500) and (Sender <> TimerResize) then
  begin
    TimerResize.Enabled := false;
    TimerResize.Enabled := true;
    LastResizeTime := Time;
    exit;
  end;

  LastResizeTime := Time;
  AnimatePlaceTilesFast;
end;


procedure TFormPuzzle15.TimerResizeTimer(Sender: TObject);
begin
  PanelClientResize(TimerResize);
  TimerResize.Enabled := false;
end;





procedure TFormPuzzle15.CalcConsts;
begin
  with PanelClient do
    if (Height > Width) then
    begin
      SpaceX := Round(Width / 20);
      TileSize := Round((Width - SpaceX * 2) / Base);
      SpaceY := SpaceX + Round((Height - Width) / 2);
    end
    else
    begin
      SpaceY := Round(Height / 20);
      TileSize := Round((Height - SpaceY * 2) / Base);
      SpaceX := SpaceY + Round((Width - Height) / 2);
    end;

  TileSpacing := Round(TileSize * 0.06);
  TileSize := Round(TileSize * 0.94);

  SpaceX := SpaceX + Round(TileSpacing / 2);
  SpaceY := SpaceY + Round(TileSpacing / 2);

end;

var slowdown: double = 1;

procedure TFormPuzzle15.AnimatePlaceTilesSlow;
var
  i, X, Y : Integer;
  Row, Col: Word;
  ScaleX, ScaleY: Extended;
begin
  CalcConsts;

  for i := 0 to Length(Tiles) - 1 do
    if (Tiles[i] <> nil) then
    begin
      ScaleX := TileSize / Tiles[i].Width;
      ScaleY := TileSize / Tiles[i].Height;
      Tiles[i].AnimateFloatDelay('Scale.X', ScaleX, 0.5, 0.9 + 0.1 * i);
      Tiles[i].AnimateFloatDelay('Scale.Y', ScaleY, 0.5, 0.8 + 0.1 * i);

      DivMod(i, Base, Row, Col);

      X := SpaceX + Round(Col * (Tiles[i].Width * ScaleX + TileSpacing));
      Y := SpaceY + Round(Row * (Tiles[i].Height * ScaleY + TileSpacing));

      Tiles[i].Tag := i;
      Tiles[i].AnimateFloatDelay('Position.X', X, 0.4, 0.5 + 0.1 * i);
      Tiles[i].AnimateFloatDelay('Position.Y', Y, 0.3, 0.5 + 0.1 * i);
    end;

end;







procedure TFormPuzzle15.AnimatePlaceTilesFast;
var
  i, X, Y: Integer;
  Row, Col: Word;
  ScaleX, ScaleY: Extended;
begin
  CalcConsts;

  for i := 0 to Length(Tiles) - 1 do
    if (Tiles[i] <> nil) then
    begin
      ScaleX := TileSize / Tiles[i].Width;
      ScaleY := TileSize / Tiles[i].Height;
      Tiles[i].AnimateFloatDelay('Scale.X', ScaleX, 0.2 * slowdown, (0.2 + 0.03 * i) * slowdown);
      Tiles[i].AnimateFloatDelay('Scale.Y', ScaleY, 0.2 * slowdown, (0.1 + 0.03 * i) * slowdown);

      DivMod(i, Base, Row, Col);

      X := SpaceX + Round(Col * (Tiles[i].Width * ScaleX + TileSpacing));
      Y := SpaceY + Round(Row * (Tiles[i].Height * ScaleY + TileSpacing));

      Tiles[i].Tag := i;
      Tiles[i].AnimateFloatDelay('Position.X', X, 0.2 * slowdown, (0 + 0.03 * i) * slowdown);
      Tiles[i].AnimateFloatDelay('Position.Y', Y, 0.1 * slowdown, (0 + 0.03 * i) * slowdown);
      {, TAnimationType.atIn, TInterpolationType.Back}
    end;
end;


procedure TFormPuzzle15.AnimateBaseNotChanged;
var
  i : Integer;
begin
  for i := 0 to Length(Tiles) - 1 do
    if (Tiles[i] <> nil) then
    begin
      Tiles[i].AnimateFloatDelay('RotationAngle', -20, 0.1 * slowdown, 0 * slowdown,
        TAnimationType.InOut, TInterpolationType.Linear  );

      Tiles[i].AnimateFloatDelay('RotationAngle', 20, 0.25 * slowdown, 0.1 * slowdown,
        TAnimationType.InOut, TInterpolationType.Exponential  );

      Tiles[i].AnimateFloatDelay('RotationAngle', 0, 0.25 * slowdown, 0.35 * slowdown,
        TAnimationType.Out, TInterpolationType.Back  );
    end;

end;




procedure TFormPuzzle15.AnimateTilesDisappeare;
var
  i: Integer;
begin
  for i := 0 to Length(Tiles) - 1 do
    if (Tiles[i] <> nil) then
    begin
      Tiles[i].AnimateFloatDelay('Scale.X', 0.1, 0.4, 0.03 * i);
      Tiles[i].AnimateFloatDelay('Scale.Y', 0.1, 0.4, 0.03 * i);
      Tiles[i].AnimateFloatDelay('RotationAngle', 45, 0.4, 0.03 * i);
      Tiles[i].AnimateFloatDelay('Position.Y', Tiles[i].Position.Y + TileSize, 0.4, 0.03 * i,
        TAnimationType.In, TInterpolationType.Back);
      Tiles[i].AnimateFloatDelay('Position.X', Tiles[i].Position.X + Round(TileSize / 2), 0.4, 0.03 * i);
      Tiles[i].AnimateFloatDelay('Opacity', 0, 0.4, 0.1 + 0.03 * i);
    end;
end;




procedure TFormPuzzle15.AnimatePrepareBeforePlace;
var
  i, X, Y: Integer;
  Row, Col: Word;
  ScaleX, ScaleY: Extended;
begin
  CalcConsts;

  for i := 0 to Length(Tiles) - 1 do
    if (Tiles[i] <> nil) then
    begin
      ScaleX := TileSize / Tiles[i].Width;
      ScaleY := TileSize / Tiles[i].Height;

      DivMod(i, Base, Row, Col);

      X := SpaceX + Round(Col * (Tiles[i].Width * ScaleX + TileSpacing));
      Y := SpaceY + Round(Row * (Tiles[i].Height * ScaleY + TileSpacing));

      Tiles[i].Scale.X := 0.1;
      Tiles[i].Scale.Y := 0.1;
      Tiles[i].RotationAngle := 45;
      Tiles[i].Opacity := 0;
      Tiles[i].Position.X := X + Round(TileSize / 2);
      Tiles[i].Position.Y := Y + TileSize;
    end;


  for i := 0 to Length(Tiles) - 1 do
    if (Tiles[i] <> nil) then
    begin
      if CheckBoxPl1.IsChecked then
        Tiles[i].Position := Tile1.Position;

      Tiles[i].AnimateFloatDelay('Opacity', 1, 0.4 * slowdown, (0.1 + 0.03 * i) * slowdown );
      Tiles[i].AnimateFloatDelay('RotationAngle', 0, 0.4 * slowdown, (0.03 * i) * slowdown );
    end;

end;



procedure TFormPuzzle15.AnimateTimeRunningOut;
var
  i: Integer;
  GradientAni: TGradientAnimation;
begin
  for i := 0 to Length(Tiles) - 1 do
    if (Tiles[i] <> nil) then
    begin

      GradientAni := (Tiles[i].Children[1] as TGradientAnimation);
      GradientAni.StopValue.Color  := TAlphaColors.Darkorange;
      GradientAni.StopValue.Color1 := TileFillNormalColor1;

      GradientAni.Delay := 0;
      GradientAni.Duration := 0.15 * slowdown;
      GradientAni.AutoReverse := true;

      GradientAni.Start;
    end;

end;


procedure TFormPuzzle15.AnimateTimeOver;
var
  i : Integer;
var  GradientAni: TGradientAnimation ;
begin
  for i := 0 to Length(Tiles) - 1 do
    if (Tiles[i] <> nil) then
    begin
      GradientAni := Tiles[i].Children[1] as TGradientAnimation;

      GradientAni.StopValue.Color := TAlphaColors.Red;
      GradientAni.StopValue.Color1 := TAlphaColors.Gray;

      GradientAni.Delay := 0;
      GradientAni.Duration := 0.6;
      GradientAni.AutoReverse := false;

      GradientAni.Start;
    end;

end;



procedure TFormPuzzle15.AnimateNormalizeTilesColor;
var
  i : Integer;
var  GradientAni: TGradientAnimation ;
begin
  for i := 0 to Length(Tiles) - 1 do
    if (Tiles[i] <> nil) then
    begin
      GradientAni := Tiles[i].Children[1] as TGradientAnimation;

      GradientAni.StopValue.Color := TileFillNormalColor;
      GradientAni.StopValue.Color1 := TileFillNormalColor1;

      GradientAni.Delay := 0;
      GradientAni.Duration := 0.2;
      GradientAni.AutoReverse := false;

      GradientAni.Start;
    end;

end;

procedure TFormPuzzle15.AnimatePuzzleMatched;
var
  i : Integer;
//  Delay: Extended;
var  GradientAni: TGradientAnimation ;
begin
  for i := 0 to Length(Tiles) - 1 do
    if (Tiles[i] <> nil) then
    begin

//      if (i = 0) then
//        Delay := 0
//      else
//        Delay := {1.7388 *} Ln(i){ + 1.9267};
//
//      Delay := Ln(i+1);

      Tiles[i].AnimateFloatDelay('RotationAngle', 360, 1, 0.35,
        TAnimationType.Out, TInterpolationType.Back  );

      GradientAni := Tiles[i].Children[1] as TGradientAnimation;

      GradientAni.Stop;
      GradientAni.StopValue.Color  := TAlphaColors.Gold;
      GradientAni.StopValue.Color1 := TAlphaColors.Lawngreen;

      GradientAni.Delay := 1 + i * 0.1;
      GradientAni.Duration := 0.5;
      GradientAni.AutoReverse := false;

      GradientAni.Start;
    end;

end;




procedure TFormPuzzle15.ButtonMenuClick(Sender: TObject);
begin
  if PanelMenuCl.Visible and (PanelMenuCl.Height = MenuFloatAnimation.StopValue) then
  begin
    MenuFloatAnimation.Inverse := true;
    MenuFloatAnimation.Start;
    exit;
  end;

  PanelMenuCl.Visible := true;
  MenuFloatAnimation.Inverse := false;
  MenuFloatAnimation.Start;
end;



procedure TFormPuzzle15.SpeedButtonEffectsClick(Sender: TObject);
begin
  PanelDebug.Visible := not PanelDebug.Visible;
  SpeedButtonEffects.IsPressed := PanelDebug.Visible;
end;




procedure TFormPuzzle15.TimerTimeTimer(Sender: TObject);
var
  Min, Sec: Word;
begin
  TextTime.Tag := TextTime.Tag - 1;
  DivMod(TextTime.Tag, 60, Min, Sec);
  TextTime.Text := Format('%d:%.2d', [Min, Sec]);

  if (TextTime.Tag = 0) then
  begin
    Mode := GameOver;

    AnimateTimeOver;
    StartBlinkShuffle;

    exit;
  end;

  if (TextTime.Tag <= 10) then
    AnimateTimeRunningOut;
end;




procedure TFormPuzzle15.ButtonCloseClick(Sender: TObject);
begin
  Close;
end;



procedure TFormPuzzle15.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if not ClosingAnimation then
  begin
    AnimateTilesDisappeare;
    ClosingAnimation := true;
    TimerClose.Interval := 520 + 30 * Length(Tiles);
    TimerClose.Enabled := true;

    Action := TCloseAction.caNone;
  end;
end;

procedure TFormPuzzle15.TimerCloseTimer(Sender: TObject);
begin
  Close;
end;



procedure TFormPuzzle15.ButtonDisappeareClick(Sender: TObject);
begin
  AnimateTilesDisappeare;
end;

procedure TFormPuzzle15.ButtonPlaceClick(Sender: TObject);
begin
  AnimatePrepareBeforePlace;
  AnimatePlaceTilesFast;
end;


procedure TFormPuzzle15.ButtonTimeRunningOutClick(Sender: TObject);
begin
  AnimateTimeRunningOut;
end;

procedure TFormPuzzle15.ButtonTimeOverClick(Sender: TObject);
begin
  AnimateTimeOver;
end;

procedure TFormPuzzle15.ButtonPuzzleMatchedClick(Sender: TObject);
begin
  AnimatePuzzleMatched;
end;

procedure TFormPuzzle15.ButtonBaseNotChangedClick(Sender: TObject);
begin
  AnimateNormalizeTilesColor;
  AnimateBaseNotChanged;
end;


end.
