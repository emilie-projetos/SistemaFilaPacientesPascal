
unit PacienteModel;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  fpjson;

type
  TPaciente = class
  private
    FId: Integer;
    FNome, FCPF, FTelefone, FSenha, FSituacao: string;
    FIdade: Integer;
    FPrioritario: Boolean;
    FConsultorioId: Integer;

  public
    // Cria um paciente e inicializa todos os seus dados.
    constructor Create(
      AId: Integer;
      const ANome, ACPF, ATelefone, ASenha, ASituacao: string;
      AIdade: Integer;
      APrioritario: Boolean;
      AConsultorioId: Integer
    );

    // Converte os dados do paciente em um objeto JSON.
    function ToJSON: TJSONObject;

    property Id: Integer read FId;
    property Nome: string read FNome write FNome;
    property CPF: string read FCPF write FCPF;
    property Telefone: string read FTelefone write FTelefone;
    property Senha: string read FSenha write FSenha;
    property Idade: Integer read FIdade write FIdade;
    property Prioritario: Boolean read FPrioritario write FPrioritario;
    property Situacao: string read FSituacao write FSituacao;
    property ConsultorioId: Integer
      read FConsultorioId write FConsultorioId;
  end;

implementation

// Inicializa os campos de um paciente.
constructor TPaciente.Create(
  AId: Integer;
  const ANome, ACPF, ATelefone, ASenha, ASituacao: string;
  AIdade: Integer;
  APrioritario: Boolean;
  AConsultorioId: Integer
);
begin
  inherited Create;

  FId := AId;
  FNome := ANome;
  FCPF := ACPF;
  FTelefone := ATelefone;
  FSenha := ASenha;
  FSituacao := ASituacao;
  FIdade := AIdade;
  FPrioritario := APrioritario;
  FConsultorioId := AConsultorioId;
end;

// Exporta os dados do paciente para serem enviados pela API.
function TPaciente.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.Add('id', FId);
  Result.Add('nome', FNome);
  Result.Add('cpf', FCPF);
  Result.Add('telefone', FTelefone);
  Result.Add('senha', FSenha);
  Result.Add('idade', FIdade);
  Result.Add('prioritario', FPrioritario);
  Result.Add('situacao', FSituacao);
  Result.Add('consultorioId', FConsultorioId);
end;

end.
