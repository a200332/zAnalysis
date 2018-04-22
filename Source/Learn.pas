{ ****************************************************************************** }
{ * machine Learn support, writen by QQ 600585@qq.com                          * }
{ * https://github.com/PassByYou888/CoreCipher                                 * }
{ * https://github.com/PassByYou888/ZServer4D                                  * }
{ * https://github.com/PassByYou888/zExpression                                * }
{ * https://github.com/PassByYou888/zTranslate                                 * }
{ * https://github.com/PassByYou888/zSound                                     * }
{ * https://github.com/PassByYou888/zAnalysis                                  * }
{ ****************************************************************************** }
unit Learn;

interface

uses CoreClasses, UnicodeMixedLib, PascalStrings, MemoryRaster, KDTree, KM,
  DataFrameEngine, MemoryStream64;

{$I zDefine.inc}


type
  TLFloat  = TKDTree_VecType;
  PLFloat  = PKDTree_VecType;
  TLVec    = TKDTree_Vec;
  PLVec    = PKDTree_Vec;
  TLMatrix = TKDTree_DynamicVecBuffer;
  PLMatrix = PKDTree_DynamicVecBuffer;

  TLInt = Integer;
  PLInt = ^TLInt;

  TLIVec    = packed array of TLInt;
  PLIVec    = ^TLIVec;
  TLIMatrix = packed array of TLIVec;
  PLIMatrix = ^TLIMatrix;

  TLearnType = (
    ltKDT,              // KDTree, fast space operation, this not Neurons network
    ltKM,               // k-means++ clusterization, this not Neurons network
    ltForest,           // random decision forest
    ltLogit,            // Logistic regression
    ltLM,               // Levenberg-Marquardt
    ltLM_MT,            // Levenberg-Marquardt with parallel
    ltLBFGS,            // L-BFGS
    ltLBFGS_MT,         // L-BFGS with parallel
    ltLBFGS_MT_Mod,     // L-BFGS with parallel and optimization
    ltMonteCarlo,       // fast Monte Carlo train
    ltLM_Ensemble,      // Levenberg-Marquardt Ensemble
    ltLM_Ensemble_MT,   // Levenberg-Marquardt Ensemble with parallel
    ltLBFGS_Ensemble,   // L-BFGS Ensemble
    ltLBFGS_Ensemble_MT // L-BFGS Ensemble with parallel
    );

const
  CLearnString: array [TLearnType] of SystemString = (
    'k-dimensional tree',
    'k-means++ clusterization',
    'Random forest',
    'Logistic regression',
    'Levenberg-Marquardt',
    'Levenberg-Marquardt with Parallel',
    'L-BFGS',
    'L-BFGS with parallel',
    'L-BFGS with parallel and optimization',
    'fast Monte Carlo',
    'Levenberg-Marquardt Ensemble',
    'Levenberg-Marquardt Ensemble with parallel',
    'L-BFGS Ensemble',
    'L-BFGS Ensemble with parallel'
    );

type
  TLearn = class;

  TLearnState_Call               = procedure(const LSender: TLearn; const state: Boolean);
  TLearnState_Method             = procedure(const LSender: TLearn; const state: Boolean) of object;
  {$IFNDEF FPC} TLearnState_Proc = reference to procedure(const LSender: TLearn; const state: Boolean); {$ENDIF}

  TLearn = class(TCoreClassInterfacedObject)
  public type
    TLearnMemory = packed record
      m_in, m_out: TLVec;
    end;

    PLearnMemory = ^TLearnMemory;
  private type
    THideLayerDepth = (hld0, hld1, hld2);

    TLearnKDT = packed record
      kdt: TKDTree;
    end;

    PLearnKDT = ^TLearnKDT;
  private
    FEnabledRandomNumber                       : Boolean;
    FInLen, FOutLen                            : TLInt;
    FMemorySource                              : TCoreClassList;
    FLearnType                                 : TLearnType;
    FLearnData                                 : Pointer;
    FClassifier                                : Boolean;
    FHideLayerDepth                            : THideLayerDepth;
    FLastTrainMaxInValue, FLastTrainMaxOutValue: TLFloat;
    FInfo                                      : SystemString;
    FIsTraining                                : Boolean;
    FTrainThreadRuning                         : Boolean;
    FUserData                                  : Pointer;
    FUserObject                                : TCoreClassObject;

    procedure KDInput(const IndexFor: NativeInt; var source: TKDTree_Source; const Data: Pointer);

    procedure FreeLearnData;
    procedure CreateLearnData(const isTrainTime: Boolean);
  public
    // regression style
    constructor CreateRegression(const lt: TLearnType; const InDataLen, OutDataLen: TLInt);
    // regression style of level 1
    constructor CreateRegression1(const lt: TLearnType; const InDataLen, OutDataLen: TLInt);
    // regression style of level 2
    constructor CreateRegression2(const lt: TLearnType; const InDataLen, OutDataLen: TLInt);

    // classifier style
    constructor CreateClassifier(const lt: TLearnType; const InDataLen: TLInt);
    // classifier style of level 1
    constructor CreateClassifier1(const lt: TLearnType; const InDataLen: TLInt);
    // classifier style of level 2
    constructor CreateClassifier2(const lt: TLearnType; const InDataLen: TLInt);

    // picture classifier style
    constructor CreatePictureClassifier(const lt: TLearnType; const SamplerWidth: TLInt);

    destructor Destroy; override;

    { * fixed random number * }
    property EnabledRandomNumber: Boolean read FEnabledRandomNumber write FEnabledRandomNumber;

    { * clear * }
    procedure Clear;

    { * parameter support * }
    function Count: TLInt;
    property InLen: TLInt read FInLen;
    property OutLen: TLInt read FOutLen;
    property LearnType: TLearnType read FLearnType;
    property Info: SystemString read FInfo;
    property TrainThreadRuning: Boolean read FTrainThreadRuning;
    function GetMemorySource(const index: TLInt): PLearnMemory;
    property MemorySource[const index: TLInt]: PLearnMemory read GetMemorySource; default;
    property LastTrainMaxInValue: TLFloat read FLastTrainMaxInValue;
    property LastTrainMaxOutValue: TLFloat read FLastTrainMaxOutValue;

    { * user parameter * }
    property UserData: Pointer read FUserData write FUserData;
    property UserObject: TCoreClassObject read FUserObject write FUserObject;

    { * add sampler support * }
    procedure AddMemory(const f_In, f_Out: TLVec); overload;
    procedure AddMemory(const s_In, s_Out: SystemString); overload;
    procedure AddMemory(const s: TPascalString); overload;
    procedure AddSampler(const f_In, f_Out: TLVec); overload;
    procedure AddSampler(const s_In, s_Out: SystemString); overload;
    procedure AddSampler(const s: TPascalString); overload;
    procedure AddMatrix(const m_in: TLMatrix; const f_Out: TLVec);

    { * normal train * }
    function Train(const TrainDepth: TLInt): Boolean; overload;
    function Train: Boolean; overload;
    { * train with thread support * }
    procedure Train_MT; overload;
    procedure Train_MT(const TrainDepth: TLInt); overload;
    procedure TrainC(const TrainDepth: TLInt; const OnResult: TLearnState_Call);
    procedure TrainM(const TrainDepth: TLInt; const OnResult: TLearnState_Method);
    {$IFNDEF FPC} procedure TrainP(const TrainDepth: TLInt; const OnResult: TLearnState_Proc); {$ENDIF FPC}
    procedure WaitTrain;
    //
    // data input/output support
    function process(const p_in, p_out: PLVec): Boolean; overload;
    function process(const ProcessIn: PLVec): SystemString; overload;
    function process(const ProcessIn: TLVec): SystemString; overload;
    function process(const ProcessIn: TPascalString): SystemString; overload;
    function processMatrix(const p_in: PLMatrix; const p_out: PLVec): Boolean; overload;
    // result max value
    function processMax(const ProcessIn: TLVec): TLFloat; overload;
    function processMax(const ProcessIn: TLMatrix): TLFloat; overload;
    // result max index
    function processMaxIndex(const ProcessIn: TLVec): TLInt; overload;
    function processMaxIndex(const ProcessIn: TLMatrix): TLInt; overload;
    // result min value
    function processMin(const ProcessIn: TLVec): TLFloat; overload;
    function processMin(const ProcessIn: TLMatrix): TLFloat; overload;
    // result min index
    function processMinIndex(const ProcessIn: TLVec): TLInt; overload;
    function processMinIndex(const ProcessIn: TLMatrix): TLInt; overload;
    // result first value
    function processFV(const ProcessIn: TLVec): TLFloat; overload;
    function processFV(const ProcessIn: TLMatrix): TLFloat; overload;
    function processFV(const ProcessIn: TPascalString): TLFloat; overload;
    // result last value
    function processLV(const ProcessIn: TLVec): TLFloat; overload;
    function processLV(const ProcessIn: TLMatrix): TLFloat; overload;
    function processLV(const ProcessIn: TPascalString): TLFloat; overload;

    // search with Pearson
    function SearchMemoryWithPearson(const ProcessIn: TLVec): TLInt; overload;
    // search with Pearson - parallel support
    procedure SearchMemoryWithPearson(const ProcessIn: TLVec; out List: TLIVec); overload;

    // search with Spearman
    function SearchMemoryWithSpearman(const ProcessIn: TLVec): TLInt; overload;
    // search with Spearman - parallel support
    procedure SearchMemoryWithSpearman(const ProcessIn: TLVec; out List: TLIVec); overload;

    // search with euclidean metric
    function SearchMemoryWithDistance(const ProcessIn: TLVec): TLInt; overload;
    // search with euclidean metric - parallel support
    procedure SearchMemoryWithDistance(const ProcessIn: TLVec; out List: TLIVec); overload;

    { * fast binary store support * }
    procedure SaveToDF(df: TDataFrameEngine);
    procedure LoadFromDF(df: TDataFrameEngine);

    { stream store support }
    procedure SaveToStream(stream: TCoreClassStream);
    procedure LoadFromStream(stream: TCoreClassStream);

    {$IFNDEF FPC}
    { * json store support * }
    procedure SaveToJsonStream(stream: TCoreClassStream);
    procedure LoadFromJsonStream(stream: TCoreClassStream);
    {$ENDIF FPC}
  end;

procedure LearnTest;

{$REGION 'LearnAPI'}
{ Normal distribution support }
function NormalDistribution(const X: TLFloat): TLFloat;
function InvNormalDistribution(const y0: TLFloat): TLFloat;

{ statistics base }
function Log1P(const X: TLFloat): TLFloat;
function ExpM1(const X: TLFloat): TLFloat;
function CosM1(const X: TLFloat): TLFloat;
{ Gamma support }
function Gamma(const X: TLFloat): TLFloat;
{ Natural logarithm of gamma function }
function LnGamma(const X: TLFloat; var SgnGam: TLFloat): TLFloat;
{ Incomplete gamma integral }
function IncompleteGamma(const A, X: TLFloat): TLFloat;
{ Complemented incomplete gamma integral }
function IncompleteGammaC(const A, X: TLFloat): TLFloat;
{ Inverse of complemented imcomplete gamma integral }
function InvIncompleteGammaC(const A, y0: TLFloat): TLFloat;

{ Poisson distribution }
function PoissonDistribution(k: TLInt; m: TLFloat): TLFloat;
{ Complemented Poisson distribution }
function PoissonCDistribution(k: TLInt; m: TLFloat): TLFloat;
{ Inverse Poisson distribution }
function InvPoissonDistribution(k: TLInt; Y: TLFloat): TLFloat;

{ Incomplete beta integral support }
function IncompleteBeta(A, B, X: TLFloat): TLFloat;
{ Inverse of imcomplete beta integral }
function InvIncompleteBeta(const A, B, Y: TLFloat): TLFloat;

{ F distribution support }
function FDistribution(const A: TLInt; const B: TLInt; const X: TLFloat): TLFloat;
{ Complemented F distribution }
function FCDistribution(const A: TLInt; const B: TLInt; const X: TLFloat): TLFloat;
{ Inverse of complemented F distribution }
function InvFDistribution(const A: TLInt; const B: TLInt; const Y: TLFloat): TLFloat;
{ Two-sample F-test }
procedure FTest(const X: TLVec; N: TLInt; const Y: TLVec; m: TLInt; var BothTails, LeftTail, RightTail: TLFloat);

{ Binomial distribution support }
function BinomialDistribution(const k, N: TLInt; const p: TLFloat): TLFloat;
{ Complemented binomial distribution }
function BinomialCDistribution(const k, N: TLInt; const p: TLFloat): TLFloat;
{ Inverse binomial distribution }
function InvBinomialDistribution(const k, N: TLInt; const Y: TLFloat): TLFloat;
{ Sign test }
procedure OneSampleSignTest(const X: TLVec; N: TLInt; Median: TLFloat; var BothTails, LeftTail, RightTail: TLFloat);

{ Chi-square distribution support }
function ChiSquareDistribution(const v, X: TLFloat): TLFloat;
{ Complemented Chi-square distribution }
function ChiSquareCDistribution(const v, X: TLFloat): TLFloat;
{ Inverse of complemented Chi-square distribution }
function InvChiSquareDistribution(const v, Y: TLFloat): TLFloat;
{ One-sample chi-square test }
procedure OneSampleVarianceTest(const X: TLVec; N: TLInt; Variance: TLFloat; var BothTails, LeftTail, RightTail: TLFloat);

{ Student's t distribution support }
function StudentTDistribution(const k: TLInt; const t: TLFloat): TLFloat;
{ Functional inverse of Student's t distribution }
function InvStudentTDistribution(const k: TLInt; p: TLFloat): TLFloat;
{ One-sample t-test }
procedure StudentTTest1(const X: TLVec; N: TLInt; Mean: TLFloat; var BothTails, LeftTail, RightTail: TLFloat);
{ Two-sample pooled test }
procedure StudentTTest2(const X: TLVec; N: TLInt; const Y: TLVec; m: TLInt; var BothTails, LeftTail, RightTail: TLFloat);
{ Two-sample unpooled test }
procedure UnequalVarianceTTest(const X: TLVec; N: TLInt; const Y: TLVec; m: TLInt; var BothTails, LeftTail, RightTail: TLFloat);

{ Pearson and Spearman distribution support }
{ Pearson product-moment correlation coefficient }
function PearsonCorrelation(const X, Y: TLVec; const N: TLInt): TLFloat;
{ Spearman's rank correlation coefficient }
function SpearmanRankCorrelation(const X, Y: TLVec; const N: TLInt): TLFloat;
procedure SpearmanRank(var X: TLVec; N: TLInt);
{ Pearson's correlation coefficient significance test }
procedure PearsonCorrelationSignificance(const R: TLFloat; const N: TLInt; var BothTails, LeftTail, RightTail: TLFloat);
{ Spearman's rank correlation coefficient significance test }
procedure SpearmanRankCorrelationSignificance(const R: TLFloat; const N: TLInt; var BothTails, LeftTail, RightTail: TLFloat);

{ Jarque-Bera test }
procedure JarqueBeraTest(const X: TLVec; const N: TLInt; var p: TLFloat);

{ Mann-Whitney U-test }
procedure MannWhitneyUTest(const X: TLVec; N: TLInt; const Y: TLVec; m: TLInt; var BothTails, LeftTail, RightTail: TLFloat);

{ Wilcoxon signed-rank test }
procedure WilcoxonSignedRankTest(const X: TLVec; N: TLInt; E: TLFloat; var BothTails, LeftTail, RightTail: TLFloat);

{ learn vector api }
function LVec(const veclen: TLInt): TLVec; overload; {$IFDEF INLINE_ASM} inline; {$ENDIF}
function LVec(const v: TLVec): TPascalString; overload; {$IFDEF INLINE_ASM} inline; {$ENDIF}
function LVec(const m: TLMatrix; const veclen: TLInt): TLVec; overload; {$IFDEF INLINE_ASM} inline; {$ENDIF}
function LVec(const m: TLMatrix): TLVec; overload; {$IFDEF INLINE_ASM} inline; {$ENDIF}
function LVec(const s: TPascalString; const veclen: TLInt): TLVec; overload; {$IFDEF INLINE_ASM} inline; {$ENDIF}
function LVec(const v: TLVec; const ShortFloat: Boolean): TPascalString; overload; {$IFDEF INLINE_ASM} inline; {$ENDIF}
function SpearmanLVec(const m: TLMatrix; const veclen: TLInt): TLVec; {$IFDEF INLINE_ASM} inline; {$ENDIF}
function MaxVec(const v: TLVec): TLFloat; {$IFDEF INLINE_ASM} inline; {$ENDIF}
function MinVec(const v: TLVec): TLFloat; {$IFDEF INLINE_ASM} inline; {$ENDIF}
function MaxVecIndex(const v: TLVec): TLInt; {$IFDEF INLINE_ASM} inline; {$ENDIF}
function MinVecIndex(const v: TLVec): TLInt; {$IFDEF INLINE_ASM} inline; {$ENDIF}
procedure Clamp(var AValue: TLFloat; const AMin, AMax: TLFloat); overload; {$IFDEF INLINE_ASM} inline; {$ENDIF}
procedure Clamp(var AValue: TLInt; const AMin, AMax: TLInt); overload; {$IFDEF INLINE_ASM} inline; {$ENDIF}

{ * sampler support * }
function MatrixSampler(const mr: TMemoryRaster): TLMatrix; overload;
function MatrixSampler(const SamplerSize: TLInt; const mr: TMemoryRaster): TLMatrix; overload;
function MatrixSampler(const Antialiasing: Boolean; const SamplerSize: TLInt; const mr: TMemoryRaster): TLMatrix; overload;
{ * linear discriminant analysis support * }
function LDA(const buff: TLMatrix; const NPoints, NVars, NClasses: TLInt; var w: TLMatrix): TLInt; overload;
function LDA(const buff: TLMatrix; const NPoints, NVars, NClasses: TLInt; var w: TLVec): TLInt; overload;
function LDA(const Fast: Boolean; const SamplerSize: TLInt; const mr: TMemoryRaster; var sInfo: SystemString; var output: TLMatrix): Boolean; overload;
{ * principal component analysis support * }
function PCA(const buff: TLMatrix; const NPoints, NVars: TLInt; var v: TLMatrix): TLInt; overload;
function PCA(const Fast: Boolean; const SamplerSize: TLInt; const mr: TMemoryRaster; var sInfo: SystemString; var output: TLMatrix): Boolean; overload;
{ * k-means++ clusterization support * }
function KMeans(const source: TKMFloat2DArray; const NVars, k: TLInt; var KArray: TKMFloat2DArray; var kIndex: TKMIntegerArray): Boolean;

{$ENDREGION 'LearnAPI'}


const
  MachineEpsilon = 5E-16;
  MaxRealNumber  = 1E300;
  MinRealNumber  = 1E-300;

implementation

uses Math,
  {$IFDEF FPC}
  mtprocs,
  {$ELSE}
  Threading,
  {$ENDIF FPC}
  SyncObjs, DoStatusIO;

{$INCLUDE Learn_Base.inc}
{$INCLUDE learn_blas.inc}
{$INCLUDE Learn_ablas.inc}
{$INCLUDE learn_trfac.inc}
{$INCLUDE learn_safesolve.inc}
{$INCLUDE learn_rcond.inc}
{$INCLUDE learn_matinv.inc}
{$INCLUDE learn_linmin.inc}
{$INCLUDE learn_lbfgs.inc}
{$INCLUDE learn_rotations.inc}
{$INCLUDE learn_ortfac.inc}
{$INCLUDE learn_bdsvd.inc}
{$INCLUDE learn_svd.inc}
{$INCLUDE learn_densesolver.inc}
{$INCLUDE learn_trainbase.inc}
{$INCLUDE learn_train.inc}
{$INCLUDE learn_trainEnsemble.inc}
{$INCLUDE learn_schur.inc}
{$INCLUDE learn_evd.inc}
{$INCLUDE learn_PCA.inc}
{$INCLUDE learn_LDA.inc}
{$INCLUDE learn_forest.inc}
{$INCLUDE learn_logit.inc}
{$INCLUDE learn_statistics_normal_distribution.inc}
{$INCLUDE learn_statistics_base.inc}
{$INCLUDE learn_statistics_IncompleteBeta.inc}
{$INCLUDE learn_statistics_fdistribution.inc}
{$INCLUDE learn_statistics_binomial_distribution.inc}
{$INCLUDE learn_statistics_chisquare_distribution.inc}
{$INCLUDE learn_statistics_StudentsT_distribution.inc}
{$INCLUDE learn_statistics_Pearson_Spearman.inc}
{$INCLUDE learn_statistics_JarqueBeraTest.inc}
{$INCLUDE learn_statistics_MannWhitneyUTest.inc}
{$INCLUDE learn_statistics_Wilcoxon.inc}
{$INCLUDE learn_extAPI.inc}
{$INCLUDE learn_th.inc}


procedure TLearn.KDInput(const IndexFor: NativeInt; var source: TKDTree_Source; const Data: Pointer);
var
  i: TLInt;
begin
  source.index := IndexFor;
  for i := 0 to FInLen - 1 do
      source.buff[i] := PLearnMemory(FMemorySource[IndexFor])^.m_in[i];
end;

procedure TLearn.FreeLearnData;
begin
  if FLearnData <> nil then
    begin
      case FLearnType of
        ltKDT, ltKM:
          begin
            DisposeObject(PLearnKDT(FLearnData)^.kdt);
            Dispose(PLearnKDT(FLearnData));
            FLearnData := nil;
          end;
        ltForest:
          begin
            Dispose(PDecisionForest(FLearnData));
            FLearnData := nil;
          end;
        ltLogit:
          begin
            Dispose(PLogitModel(FLearnData));
            FLearnData := nil;
          end;
        ltLM, ltLM_MT, ltLBFGS, ltLBFGS_MT, ltLBFGS_MT_Mod, ltMonteCarlo:
          begin
            MLPFree(PMultiLayerPerceptron(FLearnData)^);
            Dispose(PMultiLayerPerceptron(FLearnData));
            FLearnData := nil;
          end;
        ltLM_Ensemble, ltLM_Ensemble_MT, ltLBFGS_Ensemble, ltLBFGS_Ensemble_MT:
          begin
            Dispose(PMLPEnsemble(FLearnData));
            FLearnData := nil;
          end;
      end;
    end;
end;

procedure TLearn.CreateLearnData(const isTrainTime: Boolean);
var
  p_k    : PLearnKDT;
  p_f    : PDecisionForest;
  p_logit: PLogitModel;
  p_n    : PMultiLayerPerceptron;
  p_e    : PMLPEnsemble;
begin
  if not isTrainTime then
      FreeLearnData;

  case FLearnType of
    ltKDT, ltKM:
      begin
        if not isTrainTime then
          begin
            new(p_k);
            p_k^.kdt := TKDTree.Create(FInLen);
            FLearnData := p_k;
          end;
      end;
    ltForest:
      begin
        if not isTrainTime then
          begin
            new(p_f);
            FLearnData := p_f;
          end;
      end;
    ltLogit:
      begin
        if not isTrainTime then
          begin
            new(p_logit);
            FLearnData := p_logit;
          end;
      end;
    ltLM, ltLM_MT, ltLBFGS, ltLBFGS_MT, ltLBFGS_MT_Mod, ltMonteCarlo:
      begin
        if not isTrainTime then
          begin
            new(p_n);
            FLearnData := p_n;
          end
        else
            p_n := PMultiLayerPerceptron(FLearnData);

        if FClassifier then
          begin
            if isTrainTime then
              begin
                case FHideLayerDepth of
                  hld0: MLPCreateC0(FInLen, Round(FLastTrainMaxOutValue) + 1, p_n^);
                  hld1: MLPCreateC1(FInLen, FInLen, Round(FLastTrainMaxOutValue) + 1, p_n^);
                  else MLPCreateC2(FInLen, FInLen, FInLen, Round(FLastTrainMaxOutValue) + 1, p_n^);
                end;
              end;
          end
        else
          begin
            case FHideLayerDepth of
              hld0: MLPCreate0(FInLen, FOutLen, p_n^);
              hld1: MLPCreate1(FInLen, FInLen, FOutLen, p_n^);
              else MLPCreate2(FInLen, FInLen, FInLen, FOutLen, p_n^);
            end;
          end;

      end;
    ltLM_Ensemble, ltLM_Ensemble_MT, ltLBFGS_Ensemble, ltLBFGS_Ensemble_MT:
      begin
        if not isTrainTime then
          begin
            new(p_e);
            FLearnData := p_e;
          end
        else
            p_e := PMLPEnsemble(FLearnData);

        if FClassifier then
          begin
            if isTrainTime then
              begin
                case FHideLayerDepth of
                  hld0: MLPECreateC0(FInLen, Round(FLastTrainMaxOutValue) + 1, 10, p_e^);
                  hld1: MLPECreateC1(FInLen, FInLen, Round(FLastTrainMaxOutValue) + 1, 10, p_e^);
                  else MLPECreateC2(FInLen, FInLen, FInLen, Round(FLastTrainMaxOutValue) + 1, 10, p_e^);
                end;
              end;
          end
        else
          begin
            case FHideLayerDepth of
              hld0: MLPECreate0(FInLen, FOutLen, 10, p_e^);
              hld1: MLPECreate1(FInLen, FInLen, FOutLen, 10, p_e^);
              else MLPECreate2(FInLen, FInLen, FInLen, FOutLen, 10, p_e^);
            end;
          end;
      end;
  end;
end;

constructor TLearn.CreateRegression(const lt: TLearnType; const InDataLen, OutDataLen: TLInt);
begin
  inherited Create;
  if InDataLen <= 0 then
      raiseInfo('input need > 0');
  if OutDataLen <= 0 then
      raiseInfo('output need > 0');

  FEnabledRandomNumber := False;

  FInLen := InDataLen;
  FOutLen := OutDataLen;

  if (FOutLen <> 1) then
    begin
      if (lt = ltForest) then
          FOutLen := 1
      else if (lt = ltLogit) then
          FOutLen := 1;
    end;

  FMemorySource := TCoreClassList.Create;
  FLearnType := lt;

  FLearnData := nil;
  FClassifier := False;
  FHideLayerDepth := hld0;
  CreateLearnData(False);

  FLastTrainMaxInValue := 0;
  FLastTrainMaxOutValue := 0;
  FInfo := '';
  FIsTraining := False;
  FTrainThreadRuning := False;

  FUserData := nil;
  FUserObject := nil;
end;

constructor TLearn.CreateRegression1(const lt: TLearnType; const InDataLen, OutDataLen: TLInt);
begin
  inherited Create;
  if InDataLen <= 0 then
      raiseInfo('input need > 0');
  if OutDataLen <= 0 then
      raiseInfo('output need > 0');

  FEnabledRandomNumber := False;

  FInLen := InDataLen;
  FOutLen := OutDataLen;

  if (FOutLen <> 1) then
    begin
      if (lt = ltForest) then
          FOutLen := 1
      else if (lt = ltLogit) then
          FOutLen := 1;
    end;

  FMemorySource := TCoreClassList.Create;
  FLearnType := lt;

  FLearnData := nil;
  FClassifier := False;
  FHideLayerDepth := hld1;
  CreateLearnData(False);

  FLastTrainMaxInValue := 0;
  FLastTrainMaxOutValue := 0;
  FInfo := '';
  FIsTraining := False;
  FTrainThreadRuning := False;

  FUserData := nil;
  FUserObject := nil;
end;

constructor TLearn.CreateRegression2(const lt: TLearnType; const InDataLen, OutDataLen: TLInt);
begin
  inherited Create;
  if InDataLen <= 0 then
      raiseInfo('input need > 0');
  if OutDataLen <= 0 then
      raiseInfo('output need > 0');

  FEnabledRandomNumber := False;

  FInLen := InDataLen;
  FOutLen := OutDataLen;

  if (FOutLen <> 1) then
    begin
      if (lt = ltForest) then
          FOutLen := 1
      else if (lt = ltLogit) then
          FOutLen := 1;
    end;

  FMemorySource := TCoreClassList.Create;
  FLearnType := lt;

  FLearnData := nil;
  FClassifier := False;
  FHideLayerDepth := hld2;
  CreateLearnData(False);

  FLastTrainMaxInValue := 0;
  FLastTrainMaxOutValue := 0;
  FInfo := '';
  FIsTraining := False;
  FTrainThreadRuning := False;

  FUserData := nil;
  FUserObject := nil;
end;

constructor TLearn.CreateClassifier(const lt: TLearnType; const InDataLen: TLInt);
begin
  inherited Create;
  if InDataLen <= 0 then
      raiseInfo('input need > 0');

  FEnabledRandomNumber := False;

  FInLen := InDataLen;
  FOutLen := 1;
  FMemorySource := TCoreClassList.Create;
  FLearnType := lt;

  FLearnData := nil;
  FClassifier := True;
  FHideLayerDepth := hld0;
  CreateLearnData(False);

  FLastTrainMaxInValue := 0;
  FLastTrainMaxOutValue := 0;
  FInfo := '';
  FIsTraining := False;
  FTrainThreadRuning := False;

  FUserData := nil;
  FUserObject := nil;
end;

constructor TLearn.CreateClassifier1(const lt: TLearnType; const InDataLen: TLInt);
begin
  inherited Create;
  if InDataLen <= 0 then
      raiseInfo('input need > 0');

  FEnabledRandomNumber := False;

  FInLen := InDataLen;
  FOutLen := 1;
  FMemorySource := TCoreClassList.Create;
  FLearnType := lt;

  FLearnData := nil;
  FClassifier := True;
  FHideLayerDepth := hld1;
  CreateLearnData(False);

  FLastTrainMaxInValue := 0;
  FLastTrainMaxOutValue := 0;
  FInfo := '';
  FIsTraining := False;
  FTrainThreadRuning := False;

  FUserData := nil;
  FUserObject := nil;
end;

constructor TLearn.CreateClassifier2(const lt: TLearnType; const InDataLen: TLInt);
begin
  inherited Create;
  if InDataLen <= 0 then
      raiseInfo('input need > 0');

  FEnabledRandomNumber := False;

  FInLen := InDataLen;
  FOutLen := 1;
  FMemorySource := TCoreClassList.Create;
  FLearnType := lt;

  FLearnData := nil;
  FClassifier := True;
  FHideLayerDepth := hld2;
  CreateLearnData(False);

  FLastTrainMaxInValue := 0;
  FLastTrainMaxOutValue := 0;
  FInfo := '';
  FIsTraining := False;
  FTrainThreadRuning := False;

  FUserData := nil;
  FUserObject := nil;
end;

constructor TLearn.CreatePictureClassifier(const lt: TLearnType; const SamplerWidth: TLInt);
begin
  CreateClassifier(lt, SamplerWidth * SamplerWidth);
end;

destructor TLearn.Destroy;
var
  i: TLInt;
begin
  WaitTrain;

  if FMemorySource <> nil then
    begin
      for i := 0 to FMemorySource.Count - 1 do
        begin
          SetLength(PLearnMemory(FMemorySource[i])^.m_in, 0);
          SetLength(PLearnMemory(FMemorySource[i])^.m_out, 0);
          Dispose(PLearnMemory(FMemorySource[i]));
        end;
      DisposeObject(FMemorySource);
      FMemorySource := nil;
    end;

  FreeLearnData;

  FInLen := 0;
  FOutLen := 0;
  FInfo := '';
  inherited Destroy;
end;

procedure TLearn.Clear;
var
  i      : TLInt;
  p_k    : PLearnKDT;
  p_f    : PDecisionForest;
  p_logit: PLogitModel;
  p_n    : PMultiLayerPerceptron;
  p_e    : PMLPEnsemble;
begin
  WaitTrain;

  if FMemorySource <> nil then
    begin
      for i := 0 to FMemorySource.Count - 1 do
        begin
          SetLength(PLearnMemory(FMemorySource[i])^.m_in, 0);
          SetLength(PLearnMemory(FMemorySource[i])^.m_out, 0);
          Dispose(PLearnMemory(FMemorySource[i]));
        end;
      DisposeObject(FMemorySource);
      FMemorySource := nil;
    end;

  FMemorySource := TCoreClassList.Create;

  CreateLearnData(False);

  FLastTrainMaxInValue := 0;
  FLastTrainMaxOutValue := 0;
  FInfo := '';
end;

function TLearn.Count: TLInt;
begin
  Result := FMemorySource.Count;
end;

function TLearn.GetMemorySource(const index: TLInt): PLearnMemory;
begin
  Result := PLearnMemory(FMemorySource[index]);
end;

procedure TLearn.AddMemory(const f_In, f_Out: TLVec);
var
  p: PLearnMemory;
  i: TLInt;
begin
  if FIsTraining or FTrainThreadRuning then
      raiseInfo('wait Training');
  if Length(f_In) <> FInLen then
      raiseInfo('input length need = %d', [FInLen]);
  if FClassifier then
    begin
      if (Length(f_Out) <> 1) then
          raiseInfo('Classifier output length need >= 1', []);
    end
  else
    begin
      if (Length(f_Out) <> FOutLen) then
          raiseInfo('Regression output length need = %d', [FOutLen]);
    end;

  new(p);
  SetLength(p^.m_in, FInLen);
  CopyPtr(@f_In[0], @(p^.m_in[0]), FInLen * SizeOf(TLFloat));
  SetLength(p^.m_out, FOutLen);
  CopyPtr(@f_Out[0], @(p^.m_out[0]), FOutLen * SizeOf(TLFloat));

  FMemorySource.Add(p);
end;

procedure TLearn.AddMemory(const s_In, s_Out: SystemString);
var
  f_In, f_Out: TLVec;
begin
  f_In := LVec(s_In, FInLen);
  f_Out := LVec(s_Out, FOutLen);
  AddMemory(f_In, f_Out);
  SetLength(f_In, 0);
  SetLength(f_Out, 0);
end;

procedure TLearn.AddMemory(const s: TPascalString);
var
  s_In, s_Out: TPascalString;
begin
  s_In := umlGetFirstStr(s, '=');
  s_Out := umlGetLastStr(s, '=');
  AddMemory(s_In.Text, s_Out.Text);
end;

procedure TLearn.AddSampler(const f_In, f_Out: TLVec);
begin
  AddMemory(f_In, f_Out);
end;

procedure TLearn.AddSampler(const s_In, s_Out: SystemString);
begin
  AddMemory(s_In, s_Out);
end;

procedure TLearn.AddSampler(const s: TPascalString);
begin
  AddMemory(s);
end;

procedure TLearn.AddMatrix(const m_in: TLMatrix; const f_Out: TLVec);
var
  f_In: TLVec;
begin
  f_In := LVec(m_in, FInLen);
  AddMemory(f_In, f_Out);
  SetLength(f_In, 0);
end;

function TLearn.Train(const TrainDepth: TLInt): Boolean;
var
  p_k         : PLearnKDT;
  p_f         : PDecisionForest;
  p_logit     : PLogitModel;
  p_n         : PMultiLayerPerceptron;
  p_e         : PMLPEnsemble;
  kmIndexOut  : TDynamicIndexArray;
  buff        : TLMatrix;
  rInfo       : TLInt;
  mlReport    : TMLPReport;
  IsTerminated: Boolean;
  eBest       : TLFloat;
  CVRep       : TMLPCVReport;
  DFRep       : TDFReport;
  logitRep    : TMNLReport;
  bakseed     : TLInt;

  procedure BuildInternalData;
  var
    i, J: TLInt;
    v   : TLFloat;
  begin
    FLastTrainMaxInValue := PLearnMemory(FMemorySource[0])^.m_in[0];
    FLastTrainMaxOutValue := PLearnMemory(FMemorySource[0])^.m_out[0];

    if FClassifier then
      begin
        SetLength(buff, FMemorySource.Count, FInLen + 1);
        for i := 0 to FMemorySource.Count - 1 do
          begin
            for J := 0 to FInLen - 1 do
              begin
                v := PLearnMemory(FMemorySource[i])^.m_in[J];
                if v > FLastTrainMaxInValue then
                    FLastTrainMaxInValue := v;
                buff[i][J] := v;
              end;

            v := PLearnMemory(FMemorySource[i])^.m_out[0];;
            if v > FLastTrainMaxOutValue then
                FLastTrainMaxOutValue := v;
            buff[i][FInLen] := v;
          end;
        CreateLearnData(True);
      end
    else
      begin
        SetLength(buff, FMemorySource.Count, FInLen + FOutLen);
        for i := 0 to FMemorySource.Count - 1 do
          begin
            for J := 0 to FInLen - 1 do
              begin
                v := PLearnMemory(FMemorySource[i])^.m_in[J];
                if v > FLastTrainMaxInValue then
                    FLastTrainMaxInValue := v;
                buff[i][J] := v;
              end;

            for J := 0 to FOutLen - 1 do
              begin
                v := PLearnMemory(FMemorySource[i])^.m_out[J];
                if v > FLastTrainMaxOutValue then
                    FLastTrainMaxOutValue := v;
                buff[i][FInLen + J] := v;
              end;
          end;
      end;
  end;

  procedure FreeInternalData;
  begin
    SetLength(buff, 0, 0);
  end;

begin
  Result := False;

  if FIsTraining then
    begin
      FInfo := 'wait Training';
      exit;
    end;

  if FMemorySource.Count <= 0 then
    begin
      FInfo := 'Out Training set invailed';
      exit;
    end;

  FIsTraining := True;

  bakseed := RandSeed;
  if not FEnabledRandomNumber then
      RandSeed := 0;

  try
    case FLearnType of
      ltKDT:
        begin
          CreateLearnData(True);
          p_k := PLearnKDT(FLearnData);
          p_k^.kdt.Clear;
          {$IFDEF FPC}
          p_k^.kdt.BuildKDTreeM(FMemorySource.Count, nil, @KDInput);
          {$ELSE FPC}
          p_k^.kdt.BuildKDTreeM(FMemorySource.Count, nil, KDInput);
          {$ENDIF FPC}
          FInfo := 'task has been solved';
          Result := True;
        end;
      ltKM:
        begin
          CreateLearnData(True);
          p_k := PLearnKDT(FLearnData);
          p_k^.kdt.Clear;
          if (TrainDepth > 1) and (not FClassifier) then
            begin
              {$IFDEF FPC}
              p_k^.kdt.BuildKDTreeWithClusterM(FMemorySource.Count, TrainDepth, 1, kmIndexOut, nil, @KDInput);
              {$ELSE FPC}
              p_k^.kdt.BuildKDTreeWithClusterM(FMemorySource.Count, TrainDepth, 1, kmIndexOut, nil, KDInput);
              {$ENDIF FPC}
            end
          else
            begin
              {$IFDEF FPC}
              p_k^.kdt.BuildKDTreeM(FMemorySource.Count, nil, @KDInput);
              {$ELSE FPC}
              p_k^.kdt.BuildKDTreeM(FMemorySource.Count, nil, KDInput);
              {$ENDIF FPC}
            end;
          FInfo := 'task has been solved';
          Result := True;
        end;
      ltForest:
        begin
          BuildInternalData;
          p_f := PDecisionForest(FLearnData);
          if FClassifier then
              DFBuildRandomDecisionForest(buff, Length(buff), FInLen, Max(1, Round(FLastTrainMaxOutValue) + 1), 100, 1, rInfo, p_f^, DFRep)
          else
              DFBuildRandomDecisionForest(buff, Length(buff), FInLen, 1, 100, 1, rInfo, p_f^, DFRep);
          FreeInternalData;
          case rInfo of
            1: FInfo := 'task has been solved';
            -2: FInfo := 'there is a point with class number outside of [0..NClasses-1]';
            -1: FInfo := 'incorrect parameters was passed (NPoints<1, NVars<1, NClasses<1, NTrees<1, R<=0 or R>1)';
            else FInfo := 'unknow state';
          end;
          Result := (rInfo = 1);
        end;
      ltLogit:
        begin
          BuildInternalData;
          p_logit := PLogitModel(FLearnData);
          MNLTrainH(buff, Length(buff), FInLen, Max(2, Round(FLastTrainMaxOutValue) + 1), rInfo, p_logit^, logitRep);

          FreeInternalData;
          case rInfo of
            1: FInfo := 'task has been solved';
            -2: FInfo := 'there is a point with class number outside of [0..NClasses-1]';
            -1: FInfo := 'incorrect parameters was passed (NPoints<NVars+2, NVars<1, NClasses<2)';
            else FInfo := 'unknow state';
          end;
          Result := (rInfo = 1);
        end;
      ltLM:
        begin
          BuildInternalData;
          p_n := PMultiLayerPerceptron(FLearnData);
          MLPTrainLM(p_n^, buff, Length(buff), 0.001, TrainDepth, rInfo, mlReport);
          FreeInternalData;
          case rInfo of
            2: FInfo := 'task has been solved';
            -9: FInfo := 'internal matrix inverse subroutine failed';
            -2: FInfo := 'there is a point with class number outside of [0..NOut-1]';
            -1: FInfo := 'wrong parameters specified (NPoints<0, Restarts<1)';
            else FInfo := 'unknow state';
          end;
          Result := (rInfo = 2);
        end;
      ltLM_MT:
        begin
          BuildInternalData;
          p_n := PMultiLayerPerceptron(FLearnData);
          MLPTrainLM_MT(p_n^, buff, Length(buff), 0.001, TrainDepth, rInfo, mlReport);
          FreeInternalData;
          case rInfo of
            2: FInfo := 'task has been solved';
            -9: FInfo := 'internal matrix inverse subroutine failed';
            -2: FInfo := 'there is a point with class number outside of [0..NOut-1]';
            -1: FInfo := 'wrong parameters specified (NPoints<0, Restarts<1)';
            else FInfo := 'unknow state';
          end;
          Result := (rInfo = 2);
        end;
      ltLBFGS:
        begin
          BuildInternalData;
          p_n := PMultiLayerPerceptron(FLearnData);
          IsTerminated := False;
          MLPTrainLBFGS(p_n^, buff, Length(buff), 0.001, TrainDepth, 0.01, 500, rInfo, mlReport, @IsTerminated, eBest);
          FreeInternalData;
          case rInfo of
            2: FInfo := 'task has been solved';
            -8: FInfo := 'if both WStep=0 and MaxIts=0';
            -2: FInfo := 'there is a point with class number outside of [0..NOut-1]';
            -1: FInfo := 'wrong parameters specified (NPoints<0, Restarts<1)';
            else FInfo := 'unknow state';
          end;
          Result := (rInfo = 2);
        end;
      ltLBFGS_MT:
        begin
          BuildInternalData;
          p_n := PMultiLayerPerceptron(FLearnData);
          IsTerminated := False;
          MLPTrainLBFGS_MT(p_n^, buff, Length(buff), 0.001, TrainDepth, 0.01, 500, rInfo, mlReport);
          FreeInternalData;
          case rInfo of
            2: FInfo := 'task has been solved';
            -8: FInfo := 'if both WStep=0 and MaxIts=0';
            -2: FInfo := 'there is a point with class number outside of [0..NOut-1]';
            -1: FInfo := 'wrong parameters specified (NPoints<0, Restarts<1)';
            else FInfo := 'unknow state';
          end;
          Result := (rInfo = 2);
        end;
      ltLBFGS_MT_Mod:
        begin
          BuildInternalData;
          p_n := PMultiLayerPerceptron(FLearnData);
          IsTerminated := False;
          MLPTrainLBFGS_MT_Mod(p_n^, buff, Length(buff), TrainDepth, 0.01, 2.0, 500, rInfo, mlReport);
          FreeInternalData;
          case rInfo of
            2: FInfo := 'task has been solved';
            -8: FInfo := 'if both WStep=0 and MaxIts=0';
            -2: FInfo := 'there is a point with class number outside of [0..NOut-1]';
            -1: FInfo := 'wrong parameters specified (NPoints<0, Restarts<1)';
            else FInfo := 'unknow state';
          end;
          Result := (rInfo = 2);
        end;
      ltMonteCarlo:
        begin
          BuildInternalData;
          p_n := PMultiLayerPerceptron(FLearnData);
          IsTerminated := False;
          MLPTrainMonteCarlo(p_n^, buff, Length(buff), 10, TrainDepth, 0, 1, rInfo, mlReport);
          FreeInternalData;
          case rInfo of
            2: FInfo := 'task has been solved';
            -8: FInfo := 'if both WStep=0 and MaxIts=0';
            -2: FInfo := 'there is a point with class number outside of [0..NOut-1]';
            -1: FInfo := 'wrong parameters specified (NPoints<0, Restarts<1)';
            else FInfo := 'unknow state';
          end;
          Result := (rInfo = 2);
        end;
      ltLM_Ensemble, ltLM_Ensemble_MT:
        begin
          BuildInternalData;
          p_e := PMLPEnsemble(FLearnData);
          MLPEBaggingLM(FLearnType = ltLM_Ensemble_MT, p_e^, buff, Length(buff), 0.001, TrainDepth, rInfo, mlReport, CVRep);
          FreeInternalData;
          case rInfo of
            2: FInfo := 'task has been solved';
            -2: FInfo := 'there is a point with class number outside of [0..NClasses-1]';
            -1: FInfo := 'incorrect parameters was passed (NPoints<0, Restarts<1)';
            else FInfo := 'unknow state';
          end;
          Result := (rInfo = 2);
        end;
      ltLBFGS_Ensemble, ltLBFGS_Ensemble_MT:
        begin
          BuildInternalData;
          p_e := PMLPEnsemble(FLearnData);
          MLPEBaggingLBFGS(FLearnType = ltLBFGS_Ensemble_MT, p_e^, buff, Length(buff), 0.001, TrainDepth, 0.01, 500, rInfo, mlReport, CVRep);
          FreeInternalData;
          case rInfo of
            2: FInfo := 'task has been solved';
            -8: FInfo := 'both WStep=0 and MaxIts=0';
            -2: FInfo := 'there is a point with class number outside of [0..NClasses-1]';
            -1: FInfo := 'incorrect parameters was passed (NPoints<0, Restarts<1)';
            else FInfo := 'unknow state';
          end;
          Result := (rInfo = 2);
        end;
    end;
  finally
    FIsTraining := False;
    if not FEnabledRandomNumber then
        RandSeed := bakseed;
  end;
end;

function TLearn.Train: Boolean;
begin
  Result := Train(1);
end;

procedure TLearn.Train_MT;
var
  th: TLearn_th;
begin
  WaitTrain;
  FTrainThreadRuning := True;
  th := TLearn_th.Create;
  th.source := Self;
  th.TrainDepth := 1;
  th.Suspended := False;
end;

procedure TLearn.Train_MT(const TrainDepth: TLInt);
var
  th: TLearn_th;
begin
  WaitTrain;
  FTrainThreadRuning := True;
  th := TLearn_th.Create;
  th.source := Self;
  th.TrainDepth := TrainDepth;
  th.Suspended := False;
end;

procedure TLearn.TrainC(const TrainDepth: TLInt; const OnResult: TLearnState_Call);
var
  th: TLearn_th;
begin
  WaitTrain;
  FTrainThreadRuning := True;
  th := TLearn_th.Create;
  th.source := Self;
  th.OnStateC := OnResult;
  th.TrainDepth := TrainDepth;
  th.Suspended := False;
end;

procedure TLearn.TrainM(const TrainDepth: TLInt; const OnResult: TLearnState_Method);
var
  th: TLearn_th;
begin
  WaitTrain;
  FTrainThreadRuning := True;
  th := TLearn_th.Create;
  th.source := Self;
  th.OnStateM := OnResult;
  th.TrainDepth := TrainDepth;
  th.Suspended := False;
end;

{$IFNDEF FPC}


procedure TLearn.TrainP(const TrainDepth: TLInt; const OnResult: TLearnState_Proc);
var
  th: TLearn_th;
begin
  WaitTrain;
  FTrainThreadRuning := True;
  th := TLearn_th.Create;
  th.source := Self;
  th.OnStateP := OnResult;
  th.TrainDepth := TrainDepth;
  th.Suspended := False;
end;
{$ENDIF FPC}


procedure TLearn.WaitTrain;
begin
  while FTrainThreadRuning do
      CheckThreadSynchronize(1);
end;

function TLearn.process(const p_in, p_out: PLVec): Boolean;
var
  p_kd_node: PKDTree_Node;
  i        : TLInt;
  R, rmax  : TLFloat;
  List     : TLIVec;
begin
  Result := False;
  if FIsTraining or FTrainThreadRuning then
    begin
      FInfo := 'wait training';
      exit;
    end;
  if Length(p_in^) <> FInLen then
    begin
      FInfo := 'input length error';
      exit;
    end;

  case FLearnType of
    ltKDT, ltKM:
      begin
        if PLearnKDT(FLearnData)^.kdt.Count > 0 then
          begin
            if FClassifier then
              begin
                SearchMemoryWithDistance(p_in^, List);
                SetLength(p_out^, Length(List));

                for i := 0 to Length(List) - 1 do
                    p_out^[List[i]] := (Length(List) - 1) - i;
                SetLength(List, 0);
              end
            else
              begin
                p_kd_node := PLearnKDT(FLearnData)^.kdt.Search(p_in^);
                SetLength(p_out^, FOutLen);
                if p_kd_node <> nil then
                    CopyPtr(@(PLearnMemory(FMemorySource[p_kd_node^.vec^.index])^.m_out[0]), @p_out^[0], FOutLen * SizeOf(TLFloat));
              end;
            FInfo := 'successed';
            Result := True;
          end;
      end;
    ltForest:
      begin
        if Length(PDecisionForest(FLearnData)^.Trees) > 0 then
          begin
            if FClassifier then
                SetLength(p_out^, Max(1, Round(FLastTrainMaxOutValue) + 1))
            else
                SetLength(p_out^, 1);

            DFProcess(PDecisionForest(FLearnData)^, p_in^, p_out^);
            FInfo := 'successed';
            Result := True;
          end;
      end;
    ltLogit:
      begin
        if Length(PLogitModel(FLearnData)^.w) > 0 then
          begin
            SetLength(p_out^, Max(2, Round(FLastTrainMaxOutValue) + 1));

            MNLProcess(PLogitModel(FLearnData)^, p_in^, p_out^);
            FInfo := 'successed';
            Result := True;
          end;
      end;
    ltLM, ltLM_MT, ltLBFGS, ltLBFGS_MT, ltLBFGS_MT_Mod, ltMonteCarlo:
      begin
        if FClassifier then
            SetLength(p_out^, Max(2, Round(FLastTrainMaxOutValue) + 1))
        else
            SetLength(p_out^, FOutLen);

        MLPProcess(PMultiLayerPerceptron(FLearnData)^, p_in^, p_out^);
        FInfo := 'successed';
        Result := True;
      end;
    ltLM_Ensemble, ltLM_Ensemble_MT, ltLBFGS_Ensemble, ltLBFGS_Ensemble_MT:
      begin
        if FClassifier then
            SetLength(p_out^, Max(2, Round(FLastTrainMaxOutValue) + 1))
        else
            SetLength(p_out^, FOutLen);

        MLPEProcess(PMLPEnsemble(FLearnData)^, p_in^, p_out^);
        FInfo := 'successed';
        Result := True;
      end;
  end;
end;

function TLearn.process(const ProcessIn: PLVec): SystemString;
var
  ProcessOut: TLVec;
begin
  Result := '';
  if not process(ProcessIn, @ProcessOut) then
      exit;
  Result := LVec(ProcessOut, True);
end;

function TLearn.process(const ProcessIn: TLVec): SystemString;
begin
  Result := process(PLVec(@ProcessIn));
end;

function TLearn.process(const ProcessIn: TPascalString): SystemString;
begin
  Result := process(TKDTree.KDTreeVec(ProcessIn.Text));
end;

function TLearn.processMatrix(const p_in: PLMatrix; const p_out: PLVec): Boolean;
var
  f_In: TLVec;
begin
  f_In := LVec(p_in^, FInLen);
  Result := process(@f_In, p_out);
  SetLength(f_In, 0);
end;

function TLearn.processMax(const ProcessIn: TLVec): TLFloat;
var
  ProcessOut: TLVec;
  i         : TLInt;
begin
  Result := 0;
  if not process(@ProcessIn, @ProcessOut) then
      exit;

  Result := ProcessOut[0];

  if Length(ProcessOut) > 1 then
    for i := 1 to Length(ProcessOut) - 1 do
      if ProcessOut[i] > Result then
          Result := ProcessOut[i];

  SetLength(ProcessOut, 0);
end;

function TLearn.processMax(const ProcessIn: TLMatrix): TLFloat;
var
  f_In: TLVec;
begin
  f_In := LVec(ProcessIn, FInLen);
  Result := processMax(f_In);
  SetLength(f_In, 0);
end;

function TLearn.processMaxIndex(const ProcessIn: TLVec): TLInt;
var
  ProcessOut: TLVec;
  k         : TLFloat;
  i         : TLInt;
begin
  Result := -1;
  if not process(@ProcessIn, @ProcessOut) then
      exit;

  k := ProcessOut[0];
  Result := 0;

  if Length(ProcessOut) > 1 then
    for i := 1 to Length(ProcessOut) - 1 do
      if ProcessOut[i] > k then
        begin
          Result := i;
          k := ProcessOut[i];
        end;

  SetLength(ProcessOut, 0);
end;

function TLearn.processMaxIndex(const ProcessIn: TLMatrix): TLInt;
var
  f_In: TLVec;
begin
  f_In := LVec(ProcessIn, FInLen);
  Result := processMaxIndex(f_In);
  SetLength(f_In, 0);
end;

function TLearn.processMin(const ProcessIn: TLVec): TLFloat;
var
  ProcessOut: TLVec;
  i         : TLInt;
begin
  Result := 0;
  if not process(@ProcessIn, @ProcessOut) then
      exit;

  Result := ProcessOut[0];

  if Length(ProcessOut) > 1 then
    for i := 1 to Length(ProcessOut) - 1 do
      if ProcessOut[i] < Result then
          Result := ProcessOut[i];

  SetLength(ProcessOut, 0);
end;

function TLearn.processMin(const ProcessIn: TLMatrix): TLFloat;
var
  f_In: TLVec;
begin
  f_In := LVec(ProcessIn, FInLen);
  Result := processMin(f_In);
  SetLength(f_In, 0);
end;

function TLearn.processMinIndex(const ProcessIn: TLVec): TLInt;
var
  ProcessOut: TLVec;
  k         : TLFloat;
  i         : TLInt;
begin
  Result := -1;
  if not process(@ProcessIn, @ProcessOut) then
      exit;

  k := ProcessOut[0];
  Result := 0;

  if Length(ProcessOut) > 1 then
    for i := 1 to Length(ProcessOut) - 1 do
      if ProcessOut[i] < k then
        begin
          Result := i;
          k := ProcessOut[i];
        end;

  SetLength(ProcessOut, 0);
end;

function TLearn.processMinIndex(const ProcessIn: TLMatrix): TLInt;
var
  f_In: TLVec;
begin
  f_In := LVec(ProcessIn, FInLen);
  Result := processMinIndex(f_In);
  SetLength(f_In, 0);
end;

function TLearn.processFV(const ProcessIn: TLVec): TLFloat;
var
  ProcessOut: TLVec;
begin
  Result := 0;
  if not process(@ProcessIn, @ProcessOut) then
      exit;

  Result := ProcessOut[0];

  SetLength(ProcessOut, 0);
end;

function TLearn.processFV(const ProcessIn: TLMatrix): TLFloat;
var
  f_In: TLVec;
begin
  f_In := LVec(ProcessIn, FInLen);
  Result := processFV(f_In);
  SetLength(f_In, 0);
end;

function TLearn.processFV(const ProcessIn: TPascalString): TLFloat;
begin
  Result := processFV(TKDTree.KDTreeVec(ProcessIn.Text));
end;

function TLearn.processLV(const ProcessIn: TLVec): TLFloat;
var
  ProcessOut: TLVec;
begin
  Result := 0;
  if not process(@ProcessIn, @ProcessOut) then
      exit;

  Result := ProcessOut[Length(ProcessOut) - 1];

  SetLength(ProcessOut, 0);
end;

function TLearn.processLV(const ProcessIn: TLMatrix): TLFloat;
var
  f_In: TLVec;
begin
  f_In := LVec(ProcessIn, FInLen);
  Result := processLV(f_In);
  SetLength(f_In, 0);
end;

function TLearn.processLV(const ProcessIn: TPascalString): TLFloat;
begin
  Result := processLV(TKDTree.KDTreeVec(ProcessIn.Text));
end;

function TLearn.SearchMemoryWithPearson(const ProcessIn: TLVec): TLInt;
var
  k, R: TLFloat;
  i   : TLInt;
begin
  if Count <= 0 then
    begin
      Result := -1;
      exit;
    end;

  k := PearsonCorrelation(ProcessIn, GetMemorySource(0)^.m_in, FInLen);
  Result := 0;

  for i := 1 to Count - 1 do
    begin
      R := PearsonCorrelation(ProcessIn, GetMemorySource(i)^.m_in, FInLen);
      if (R <> 0) and (R > k) then
        begin
          k := R;
          Result := i;
        end;
    end;
end;

procedure TLearn.SearchMemoryWithPearson(const ProcessIn: TLVec; out List: TLIVec);
{$REGION 'Imp'}

type
  TState = record
    k: TLFloat;
    index: TLInt;
  end;

  PState = ^TState;

  TStatePtrArray = array of PState;
  TStateArray    = array of TState;

  function SortCompare(const p1, p2: PState): ShortInt; inline;
  begin
    if p1^.k > p2^.k then
        Result := -1
    else if p1^.k < p2^.k then
        Result := 1
    else
        Result := 0;
  end;
  procedure InternalSort(var SortBuffer: TStatePtrArray; l, R: TLInt);
  var
    i, J: TLInt;
    p, t: PState;
  begin
    repeat
      i := l;
      J := R;
      p := SortBuffer[(l + R) shr 1];
      repeat
        while SortCompare(SortBuffer[i], p) < 0 do
            inc(i);
        while SortCompare(SortBuffer[J], p) > 0 do
            Dec(J);
        if i <= J then
          begin
            if i <> J then
              begin
                t := SortBuffer[i];
                SortBuffer[i] := SortBuffer[J];
                SortBuffer[J] := t;
              end;
            inc(i);
            Dec(J);
          end;
      until i > J;
      if l < J then
          InternalSort(SortBuffer, l, J);
      l := i;
    until i >= R;
  end;

var
  buff   : TStateArray;
  buffPtr: TStatePtrArray;

  {$IFDEF FPC}
  procedure Nested_ParallelFor(pass: PtrInt; Data: Pointer; Item: TMultiThreadProcItem);
  begin
    buff[pass].k := PearsonCorrelation(ProcessIn, GetMemorySource(pass)^.m_in, FInLen);
    buff[pass].index := pass;
    buffPtr[pass] := @buff[pass];
  end;
{$ENDIF FPC}


var
  i: TLInt;
begin
  if Count <= 0 then
      exit;
  if Count = 1 then
    begin
      SetLength(List, 1);
      List[0] := 0;
      exit;
    end;
  SetLength(buff, Count);
  SetLength(buffPtr, Count);

  {$IFDEF parallel}
  {$IFDEF FPC}
  ProcThreadPool.DoParallelLocalProc(@Nested_ParallelFor, 0, Count - 1);
  {$ELSE}
  TParallel.For(0, Count - 1, procedure(pass: TLInt)
    begin
      buff[pass].k := PearsonCorrelation(ProcessIn, GetMemorySource(pass)^.m_in, FInLen);
      buff[pass].index := pass;
      buffPtr[pass] := @buff[pass];
    end);
  {$ENDIF FPC}
  {$ELSE}
  for i := 0 to Count - 1 do
    begin
      buff[i].k := PearsonCorrelation(ProcessIn, GetMemorySource(i)^.m_in, FInLen);
      buff[i].index := i;
      buffPtr[i] := @buff[i];
    end;
  {$ENDIF parallel}
  // complete sort
  InternalSort(buffPtr, 0, Length(buffPtr) - 1);

  SetLength(List, Count);
  for i := 0 to Count - 1 do
      List[i] := buffPtr[i]^.index;

  SetLength(buff, 0);
  SetLength(buffPtr, 0);
end;
{$ENDREGION 'Imp'}


function TLearn.SearchMemoryWithSpearman(const ProcessIn: TLVec): TLInt;
var
  k, R: TLFloat;
  i   : TLInt;
begin
  if Count <= 0 then
    begin
      Result := -1;
      exit;
    end;

  k := SpearmanRankCorrelation(ProcessIn, GetMemorySource(0)^.m_in, FInLen);
  Result := 0;

  for i := 1 to Count - 1 do
    begin
      R := SpearmanRankCorrelation(ProcessIn, GetMemorySource(i)^.m_in, FInLen);
      if (R <> 0) and (R > k) then
        begin
          k := R;
          Result := i;
        end;
    end;
end;

procedure TLearn.SearchMemoryWithSpearman(const ProcessIn: TLVec; out List: TLIVec);
{$REGION 'Imp'}

type
  TState = record
    k: TLFloat;
    index: TLInt;
  end;

  PState = ^TState;

  TStatePtrArray = array of PState;
  TStateArray    = array of TState;

  function SortCompare(const p1, p2: PState): ShortInt; inline;
  begin
    if p1^.k > p2^.k then
        Result := -1
    else if p1^.k < p2^.k then
        Result := 1
    else
        Result := 0;
  end;
  procedure InternalSort(var SortBuffer: TStatePtrArray; l, R: TLInt);
  var
    i, J: TLInt;
    p, t: PState;
  begin
    repeat
      i := l;
      J := R;
      p := SortBuffer[(l + R) shr 1];
      repeat
        while SortCompare(SortBuffer[i], p) < 0 do
            inc(i);
        while SortCompare(SortBuffer[J], p) > 0 do
            Dec(J);
        if i <= J then
          begin
            if i <> J then
              begin
                t := SortBuffer[i];
                SortBuffer[i] := SortBuffer[J];
                SortBuffer[J] := t;
              end;
            inc(i);
            Dec(J);
          end;
      until i > J;
      if l < J then
          InternalSort(SortBuffer, l, J);
      l := i;
    until i >= R;
  end;

var
  buff   : TStateArray;
  buffPtr: TStatePtrArray;

  {$IFDEF FPC}
  procedure Nested_ParallelFor(pass: PtrInt; Data: Pointer; Item: TMultiThreadProcItem);
  begin
    buff[pass].k := SpearmanRankCorrelation(ProcessIn, GetMemorySource(pass)^.m_in, FInLen);
    buff[pass].index := pass;
    buffPtr[pass] := @buff[pass];
  end;
{$ENDIF FPC}


var
  i: TLInt;
begin
  if Count <= 0 then
      exit;
  if Count = 1 then
    begin
      SetLength(List, 1);
      List[0] := 0;
      exit;
    end;
  SetLength(buff, Count);
  SetLength(buffPtr, Count);

  {$IFDEF parallel}
  {$IFDEF FPC}
  ProcThreadPool.DoParallelLocalProc(@Nested_ParallelFor, 0, Count - 1);
  {$ELSE}
  TParallel.For(0, Count - 1, procedure(pass: TLInt)
    begin
      buff[pass].k := SpearmanRankCorrelation(ProcessIn, GetMemorySource(pass)^.m_in, FInLen);
      buff[pass].index := pass;
      buffPtr[pass] := @buff[pass];
    end);
  {$ENDIF FPC}
  {$ELSE}
  for i := 0 to Count - 1 do
    begin
      buff[i].k := SpearmanRankCorrelation(ProcessIn, GetMemorySource(i)^.m_in, FInLen);
      buff[i].index := i;
      buffPtr[i] := @buff[i];
    end;
  {$ENDIF parallel}
  // complete sort
  InternalSort(buffPtr, 0, Length(buffPtr) - 1);

  SetLength(List, Count);
  for i := 0 to Count - 1 do
      List[i] := buffPtr[i]^.index;

  SetLength(buff, 0);
  SetLength(buffPtr, 0);
end;
{$ENDREGION 'Imp'}


function TLearn.SearchMemoryWithDistance(const ProcessIn: TLVec): TLInt;
var
  k, R: Double;
  i   : TLInt;
begin
  if Count <= 0 then
    begin
      Result := -1;
      exit;
    end;

  if Length(ProcessIn) <> FInLen then
      raiseInfo('processIn need Length=%d', [FInLen]);
  k := TKDTree.KDTreeDistance(ProcessIn, GetMemorySource(0)^.m_in);
  Result := 0;

  for i := 1 to Count - 1 do
    begin
      R := TKDTree.KDTreeDistance(ProcessIn, GetMemorySource(i)^.m_in);
      if (R < k) then
        begin
          k := R;
          Result := i;
        end;
    end;
end;

procedure TLearn.SearchMemoryWithDistance(const ProcessIn: TLVec; out List: TLIVec);
type
  TState = record
    k: Double;
    index: TLInt;
  end;

  PState = ^TState;

  TStatePtrArray = array of PState;
  TStateArray    = array of TState;

  function SortCompare(const p1, p2: PState): ShortInt; inline;
  begin
    if p1^.k < p2^.k then
        Result := -1
    else if p1^.k > p2^.k then
        Result := 1
    else
        Result := 0;
  end;
  procedure InternalSort(var SortBuffer: TStatePtrArray; l, R: TLInt);
  var
    i, J: TLInt;
    p, t: PState;
  begin
    repeat
      i := l;
      J := R;
      p := SortBuffer[(l + R) shr 1];
      repeat
        while SortCompare(SortBuffer[i], p) < 0 do
            inc(i);
        while SortCompare(SortBuffer[J], p) > 0 do
            Dec(J);
        if i <= J then
          begin
            if i <> J then
              begin
                t := SortBuffer[i];
                SortBuffer[i] := SortBuffer[J];
                SortBuffer[J] := t;
              end;
            inc(i);
            Dec(J);
          end;
      until i > J;
      if l < J then
          InternalSort(SortBuffer, l, J);
      l := i;
    until i >= R;
  end;

var
  buff   : TStateArray;
  buffPtr: TStatePtrArray;

  {$IFDEF FPC}
  procedure Nested_ParallelFor(pass: PtrInt; Data: Pointer; Item: TMultiThreadProcItem);
  begin
    buff[pass].k := TKDTree.KDTreeDistance(ProcessIn, GetMemorySource(pass)^.m_in);
    buff[pass].index := pass;
    buffPtr[pass] := @buff[pass];
  end;
{$ENDIF FPC}


var
  i: TLInt;
begin
  if Count <= 0 then
    begin
      exit;
    end;

  if Count < 2 then
    begin
      SetLength(List, 1);
      List[0] := 0;
      exit;
    end;

  SetLength(buff, Count);
  SetLength(buffPtr, Count);

  {$IFDEF parallel}
  {$IFDEF FPC}
  ProcThreadPool.DoParallelLocalProc(@Nested_ParallelFor, 0, Count - 1);
  {$ELSE}
  TParallel.For(0, Count - 1, procedure(pass: TLInt)
    begin
      buff[pass].k := TKDTree.KDTreeDistance(ProcessIn, GetMemorySource(pass)^.m_in);
      buff[pass].index := pass;
      buffPtr[pass] := @buff[pass];
    end);
  {$ENDIF FPC}
  {$ELSE}
  for i := 0 to Count - 1 do
    begin
      buff[i].k := TKDTree.KDTreeDistance(ProcessIn, GetMemorySource(i)^.m_in);
      buff[i].index := i;
      buffPtr[i] := @buff[i];
    end;
  {$ENDIF parallel}
  // complete sort
  InternalSort(buffPtr, 0, Length(buffPtr) - 1);

  SetLength(List, Count);
  for i := 0 to Count - 1 do
      List[i] := buffPtr[i]^.index;

  SetLength(buff, 0);
  SetLength(buffPtr, 0);
end;

procedure TLearn.SaveToDF(df: TDataFrameEngine);
var
  ar     : TDataFrameArrayDouble;
  i, J   : TLInt;
  buff   : TLVec;
  buffLen: TLInt;
  m64    : TMemoryStream64;
begin
  df.WriteInt64(FInLen);
  df.WriteInt64(FOutLen);
  df.WriteByte(Byte(FLearnType));
  df.WriteBool(FEnabledRandomNumber);
  df.WriteBool(FClassifier);
  df.WriteByte(Byte(FHideLayerDepth));
  df.WriteDouble(FLastTrainMaxInValue);
  df.WriteDouble(FLastTrainMaxOutValue);

  ar := df.WriteArrayDouble;
  for i := 0 to FMemorySource.Count - 1 do
    begin
      for J := 0 to FInLen - 1 do
          ar.Add(PLearnMemory(FMemorySource[i])^.m_in[J]);
      for J := 0 to FOutLen - 1 do
          ar.Add(PLearnMemory(FMemorySource[i])^.m_out[J]);
    end;

  case FLearnType of
    ltKDT, ltKM:
      begin
        if PLearnKDT(FLearnData)^.kdt.Count > 0 then
          begin
            m64 := TMemoryStream64.Create;
            PLearnKDT(FLearnData)^.kdt.SaveToStream(m64);
            df.WriteStream(m64);
            DisposeObject(m64);
          end;
      end;
    ltForest:
      begin
        if Length(PDecisionForest(FLearnData)^.Trees) > 0 then
          begin
            DFSerialize(PDecisionForest(FLearnData)^, buff, buffLen);
            ar := df.WriteArrayDouble;
            for i := 0 to buffLen - 1 do
                ar.Add(buff[i]);
          end;
      end;
    ltLogit:
      begin
        if Length(PLogitModel(FLearnData)^.w) > 0 then
          begin
            MNLSerialize(PLogitModel(FLearnData)^, buff, buffLen);
            ar := df.WriteArrayDouble;
            for i := 0 to buffLen - 1 do
                ar.Add(buff[i]);
          end;
      end;
    ltLM, ltLM_MT, ltLBFGS, ltLBFGS_MT, ltLBFGS_MT_Mod, ltMonteCarlo:
      begin
        if Length(PMultiLayerPerceptron(FLearnData)^.Neurons) > 0 then
          begin
            MLPSerialize(PMultiLayerPerceptron(FLearnData)^, buff, buffLen);
            ar := df.WriteArrayDouble;
            for i := 0 to buffLen - 1 do
                ar.Add(buff[i]);
          end;
      end;
    ltLM_Ensemble, ltLM_Ensemble_MT, ltLBFGS_Ensemble, ltLBFGS_Ensemble_MT:
      begin
        if Length(PMLPEnsemble(FLearnData)^.DFDNET) > 0 then
          begin
            MLPESerialize(PMLPEnsemble(FLearnData)^, buff, buffLen);
            ar := df.WriteArrayDouble;
            for i := 0 to buffLen - 1 do
                ar.Add(buff[i]);
          end;
      end;
  end;
end;

procedure TLearn.LoadFromDF(df: TDataFrameEngine);
var
  ar  : TDataFrameArrayDouble;
  i, J: TLInt;
  plm : PLearnMemory;
  buff: TLVec;
  m64 : TMemoryStream64;
begin
  Clear;

  FInLen := df.Reader.ReadInt64;
  FOutLen := df.Reader.ReadInt64;
  FLearnType := TLearnType(df.Reader.ReadByte);
  FEnabledRandomNumber := df.Reader.ReadBool;
  FClassifier := df.Reader.ReadBool;
  FHideLayerDepth := THideLayerDepth(df.Reader.ReadByte);
  FLastTrainMaxInValue := df.Reader.ReadDouble;
  FLastTrainMaxOutValue := df.Reader.ReadDouble;

  ar := df.Reader.ReadArrayDouble;

  i := 0;
  while i < ar.Count do
    begin
      new(plm);
      SetLength(plm^.m_in, FInLen);
      SetLength(plm^.m_out, FOutLen);
      FMemorySource.Add(plm);

      J := 0;
      while J < FInLen do
        begin
          plm^.m_in[J] := ar[i];
          inc(J);
          inc(i);
        end;

      J := 0;
      while J < FOutLen do
        begin
          plm^.m_out[J] := ar[i];
          inc(J);
          inc(i);
        end;
    end;

  if df.Reader.IsEnd then
    begin
      Train;
      exit;
    end;

  case FLearnType of
    ltKDT, ltKM:
      begin
        m64 := TMemoryStream64.Create;
        df.Reader.ReadStream(m64);
        m64.Position := 0;
        try
            PLearnKDT(FLearnData)^.kdt.LoadFromStream(m64);
        except
            Train;
        end;
        DisposeObject(m64);
      end;
    ltForest:
      begin
        ar := df.Reader.ReadArrayDouble;
        SetLength(buff, ar.Count);
        for i := 0 to ar.Count - 1 do
            buff[i] := ar[i];

        try
            DFUnserialize(buff, PDecisionForest(FLearnData)^);
        except
            Train;
        end;
        SetLength(buff, 0);
      end;
    ltLogit:
      begin
        ar := df.Reader.ReadArrayDouble;
        SetLength(buff, ar.Count);
        for i := 0 to ar.Count - 1 do
            buff[i] := ar[i];

        try
            MNLUnserialize(buff, PLogitModel(FLearnData)^);
        except
            Train;
        end;
        SetLength(buff, 0);
      end;
    ltLM, ltLM_MT, ltLBFGS, ltLBFGS_MT, ltLBFGS_MT_Mod, ltMonteCarlo:
      begin
        ar := df.Reader.ReadArrayDouble;
        SetLength(buff, ar.Count);
        for i := 0 to ar.Count - 1 do
            buff[i] := ar[i];

        try
            MLPUNSerialize(buff, PMultiLayerPerceptron(FLearnData)^);
        except
            Train;
        end;
        SetLength(buff, 0);
      end;
    ltLM_Ensemble, ltLM_Ensemble_MT, ltLBFGS_Ensemble, ltLBFGS_Ensemble_MT:
      begin
        ar := df.Reader.ReadArrayDouble;
        SetLength(buff, ar.Count);
        for i := 0 to ar.Count - 1 do
            buff[i] := ar[i];

        try
            MLPEUNSerialize(buff, PMLPEnsemble(FLearnData)^);
        except
            Train;
        end;
        SetLength(buff, 0);
      end;
  end;
end;

procedure TLearn.SaveToStream(stream: TCoreClassStream);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;

  SaveToDF(de);

  de.EncodeTo(stream, True);
  DisposeObject(de);
end;

procedure TLearn.LoadFromStream(stream: TCoreClassStream);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;
  de.DecodeFrom(stream, True);

  LoadFromDF(de);

  DisposeObject(de);
end;

{$IFNDEF FPC}


procedure TLearn.SaveToJsonStream(stream: TCoreClassStream);
var
  de: TDataFrameEngine;
begin
  de := TDataFrameEngine.Create;

  SaveToDF(de);

  de.EncodeAsPublicJson(stream);
  DisposeObject(de);
end;

procedure TLearn.LoadFromJsonStream(stream: TCoreClassStream);
var
  de: TDataFrameEngine;
begin
  Clear;

  de := TDataFrameEngine.Create;
  de.DecodeFromJson(stream);

  LoadFromDF(de);

  DisposeObject(de);
end;
{$ENDIF FPC}

{$INCLUDE learn_test.inc}

initialization

end.
