
unit ClinicaRepository;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser, PacienteModel;

type
  // Representa um consultório e o paciente que está sendo atendido nele.
  TConsultorio = record
    Id: Integer;
    Sala: string;
    Profissional: string;
    Ocupado: Boolean;
    PacienteId: Integer;
  end;

  TPacienteArray = array of TPaciente;

  TClinicaRepository = class
  private
    FArquivo: string;
    FPacientes: TPacienteArray;
    FSalas: array of TConsultorio;
    FProximoId, FProximaSala, FNormal, FPrioridade: Integer;

    // Localiza um paciente pelo identificador.
    function IndicePaciente(AId: Integer): Integer;

    // Localiza um paciente pelo CPF.
    function IndiceCPF(const ACPF: string): Integer;

    // Localiza um consultório pelo identificador.
    function IndiceSala(AId: Integer): Integer;

    // Lê os dados persistidos no arquivo JSON.
    procedure Carregar;

    // Salva pacientes e consultórios no arquivo JSON.
    procedure Salvar;

  public
    // Inicializa o repositório e carrega os dados existentes.
    constructor Create(const NomeArquivo: string);

    // Libera os objetos de paciente criados pelo repositório.
    destructor Destroy; override;

    // Retorna a lista de pacientes em formato JSON.
    function ListarPacientes: TJSONArray;

    // Retorna a lista de consultórios em formato JSON.
    function ListarSalas: TJSONArray;

    // Valida e cadastra um paciente, gerando uma senha.
    function CadastrarPaciente(
      const Nome, CPF, Telefone: string;
      Idade: Integer;
      out Msg: string
    ): TJSONObject;

    // Cadastra um profissional e seu consultório.
    function CadastrarSala(
      const Profissional, Sala: string;
      out Msg: string
    ): TJSONObject;

    // Chama o próximo paciente da categoria informada.
    function ChamarProximo(
      const Tipo: string;
      out Msg: string
    ): TJSONObject;

    // Finaliza o atendimento e libera o consultório.
    function Finalizar(
      AConsultorioId: Integer;
      out Msg: string
    ): Boolean;

    // Remove um paciente que não esteja em atendimento.
    function RemoverPaciente(
      AId: Integer;
      out Msg: string
    ): Boolean;

    // Atualiza os dados cadastrais de um paciente.
    function EditarPaciente(
      AId: Integer;
      const Nome, CPF, Telefone: string;
      Idade: Integer;
      out Msg: string
    ): TJSONObject;
  end;

implementation

// Inicializa os contadores e carrega os dados salvos.
constructor TClinicaRepository.Create(const NomeArquivo: string);
begin
  inherited Create;
  FArquivo := NomeArquivo;
  FProximoId := 1;
  FProximaSala := 1;
  FNormal := 0;
  FPrioridade := 0;
  Carregar;
end;

// Libera todos os objetos de paciente antes de destruir o repositório.
destructor TClinicaRepository.Destroy;
var
  I: Integer;
begin
  for I := 0 to High(FPacientes) do
    FPacientes[I].Free;

  inherited Destroy;
end;

// Retorna o índice do paciente ou -1 se ele não existir.
function TClinicaRepository.IndicePaciente(AId: Integer): Integer;
var
  I: Integer;
begin
  Result := -1;

  for I := 0 to High(FPacientes) do
    if FPacientes[I].Id = AId then
      Exit(I);
end;

// Retorna o índice de um CPF já cadastrado ou -1.
function TClinicaRepository.IndiceCPF(const ACPF: string): Integer;
var
  I: Integer;
begin
  Result := -1;

  for I := 0 to High(FPacientes) do
    if FPacientes[I].CPF = Trim(ACPF) then
      Exit(I);
end;

// Retorna o índice do consultório ou -1 se ele não existir.
function TClinicaRepository.IndiceSala(AId: Integer): Integer;
var
  I: Integer;
begin
  Result := -1;

  for I := 0 to High(FSalas) do
    if FSalas[I].Id = AId then
      Exit(I);
end;

// Carrega pacientes e consultórios do arquivo JSON.
procedure TClinicaRepository.Carregar;
var
  L: TStringList;
  D: TJSONData;
  Raiz, O: TJSONObject;
  A: TJSONArray;
  I, NumeroSenha: Integer;
  P: TPaciente;
begin
  if not FileExists(FArquivo) then
    Exit;

  L := TStringList.Create;
  try
    L.LoadFromFile(FArquivo);
    D := GetJSON(L.Text);
  finally
    L.Free;
  end;

  try
    if D.JSONType <> jtObject then
      Exit;

    Raiz := TJSONObject(D);

    if Raiz.Find('pacientes') <> nil then
    begin
      A := Raiz.Arrays['pacientes'];

      for I := 0 to A.Count - 1 do
      begin
        O := A.Objects[I];

        P := TPaciente.Create(
          O.Get('id', 0),
          O.Get('nome', ''),
          O.Get('cpf', ''),
          O.Get('telefone', ''),
          O.Get('senha', ''),
          O.Get('situacao', 'Aguardando'),
          O.Get('idade', 0),
          O.Get('prioritario', False),
          O.Get('consultorioId', 0)
        );

        SetLength(FPacientes, Length(FPacientes) + 1);
        FPacientes[High(FPacientes)] := P;

        if P.Id >= FProximoId then
          FProximoId := P.Id + 1;

        NumeroSenha := StrToIntDef(Copy(P.Senha, 2, MaxInt), 0);

        if (Length(P.Senha) > 1) and (P.Senha[1] = 'P') then
          if NumeroSenha > FPrioridade then
            FPrioridade := NumeroSenha;

        if (Length(P.Senha) > 1) and (P.Senha[1] = 'N') then
          if NumeroSenha > FNormal then
            FNormal := NumeroSenha;
      end;
    end;

    if Raiz.Find('consultorios') <> nil then
    begin
      A := Raiz.Arrays['consultorios'];

      for I := 0 to A.Count - 1 do
      begin
        O := A.Objects[I];

        SetLength(FSalas, Length(FSalas) + 1);

        FSalas[High(FSalas)].Id := O.Get('id', 0);
        FSalas[High(FSalas)].Sala := O.Get('sala', '');
        FSalas[High(FSalas)].Profissional :=
          O.Get('profissional', '');
        FSalas[High(FSalas)].Ocupado := O.Get('ocupado', False);
        FSalas[High(FSalas)].PacienteId :=
          O.Get('pacienteId', 0);

        if FSalas[High(FSalas)].Id >= FProximaSala then
          FProximaSala := FSalas[High(FSalas)].Id + 1;
      end;
    end;
  finally
    D.Free;
  end;
end;

// Grava o estado atual dos pacientes e consultórios no arquivo JSON.
procedure TClinicaRepository.Salvar;
var
  D, O: TJSONObject;
  A, B: TJSONArray;
  I: Integer;
  L: TStringList;
begin
  D := TJSONObject.Create;
  A := TJSONArray.Create;
  B := TJSONArray.Create;

  try
    for I := 0 to High(FPacientes) do
      A.Add(FPacientes[I].ToJSON);

    for I := 0 to High(FSalas) do
    begin
      O := TJSONObject.Create;
      O.Add('id', FSalas[I].Id);
      O.Add('sala', FSalas[I].Sala);
      O.Add('profissional', FSalas[I].Profissional);
      O.Add('ocupado', FSalas[I].Ocupado);
      O.Add('pacienteId', FSalas[I].PacienteId);
      B.Add(O);
    end;

    D.Add('pacientes', A);
    D.Add('consultorios', B);

    ForceDirectories(ExtractFileDir(FArquivo));

    L := TStringList.Create;
    try
      L.Text := D.FormatJSON;
      L.SaveToFile(FArquivo);
    finally
      L.Free;
    end;
  finally
    D.Free;
  end;
end;

// Monta a lista JSON de pacientes.
function TClinicaRepository.ListarPacientes: TJSONArray;
var
  I: Integer;
begin
  Result := TJSONArray.Create;

  for I := 0 to High(FPacientes) do
    Result.Add(FPacientes[I].ToJSON);
end;

// Monta a lista JSON de consultórios, incluindo o nome do paciente atendido.
function TClinicaRepository.ListarSalas: TJSONArray;
var
  I, J: Integer;
  O: TJSONObject;
begin
  Result := TJSONArray.Create;

  for I := 0 to High(FSalas) do
  begin
    O := TJSONObject.Create;
    O.Add('id', FSalas[I].Id);
    O.Add('sala', FSalas[I].Sala);
    O.Add('profissional', FSalas[I].Profissional);
    O.Add('ocupado', FSalas[I].Ocupado);
    O.Add('pacienteId', FSalas[I].PacienteId);

    J := IndicePaciente(FSalas[I].PacienteId);

    if J >= 0 then
      O.Add('pacienteNome', FPacientes[J].Nome)
    else
      O.Add('pacienteNome', '');

    Result.Add(O);
  end;
end;

// Valida os dados, impede CPF duplicado e gera a senha da fila.
function TClinicaRepository.CadastrarPaciente(
  const Nome, CPF, Telefone: string;
  Idade: Integer;
  out Msg: string
): TJSONObject;
var
  P: TPaciente;
  Prior: Boolean;
  Senha: string;
begin
  Result := nil;

  if Trim(Nome) = '' then
  begin
    Msg := 'Informe o nome.';
    Exit;
  end;

  if (Length(CPF) <> 11) or (Trim(CPF) <> CPF) then
  begin
    Msg := 'Informe o CPF com exatamente 11 dígitos.';
    Exit;
  end;

  if IndiceCPF(CPF) >= 0 then
  begin
    Msg := 'Já existe paciente com esse CPF.';
    Exit;
  end;

  if (Idade < 0) or (Idade > 120) then
  begin
    Msg := 'Idade deve estar entre 0 e 120.';
    Exit;
  end;

  Prior := Idade >= 60;

  if Prior then
  begin
    Inc(FPrioridade);
    Senha := 'P' + IntToStr(FPrioridade);
  end
  else
  begin
    Inc(FNormal);
    Senha := 'N' + IntToStr(FNormal);
  end;

  P := TPaciente.Create(
    FProximoId, Trim(Nome), CPF, Trim(Telefone), Senha,
    'Aguardando', Idade, Prior, 0
  );

  Inc(FProximoId);
  SetLength(FPacientes, Length(FPacientes) + 1);
  FPacientes[High(FPacientes)] := P;

  Salvar;
  Result := P.ToJSON;
  Msg := 'Paciente cadastrado. Senha: ' + Senha;
end;

// Valida e cadastra um consultório ainda não existente.
function TClinicaRepository.CadastrarSala(
  const Profissional, Sala: string;
  out Msg: string
): TJSONObject;
var
  I: Integer;
  O: TJSONObject;
  SalaNova, ProfissionalNovo: string;
begin
  Result := nil;
  SalaNova := Trim(Sala);
  ProfissionalNovo := Trim(Profissional);

  if (ProfissionalNovo = '') or (SalaNova = '') then
  begin
    Msg := 'Informe profissional e consultório.';
    Exit;
  end;

  for I := 0 to High(FSalas) do
    if SameText(FSalas[I].Sala, SalaNova) then
    begin
      Msg := 'Esse consultório já está cadastrado.';
      Exit;
    end;

  SetLength(FSalas, Length(FSalas) + 1);

  with FSalas[High(FSalas)] do
  begin
    Id := FProximaSala;
    Inc(FProximaSala);
    Sala := SalaNova;
    Profissional := ProfissionalNovo;
    Ocupado := False;
    PacienteId := 0;
  end;

  O := TJSONObject.Create;
  O.Add('id', FProximaSala - 1);
  O.Add('sala', SalaNova);
  O.Add('profissional', ProfissionalNovo);
  O.Add('ocupado', False);
  O.Add('pacienteId', 0);

  Result := O;
  Salvar;
  Msg := 'Profissional e consultório cadastrados.';
end;

// Chama o paciente aguardando há mais tempo na categoria selecionada.
function TClinicaRepository.ChamarProximo(
  const Tipo: string;
  out Msg: string
): TJSONObject;
var
  I, J, K: Integer;
  Prior: Boolean;
begin
  Result := nil;

  if Length(FSalas) = 0 then
  begin
    Msg := 'Cadastre um profissional e consultório primeiro.';
    Exit;
  end;

  J := -1;

  for I := 0 to High(FSalas) do
    if not FSalas[I].Ocupado then
    begin
      J := I;
      Break;
    end;

  if J < 0 then
  begin
    Msg := 'Não há consultórios livres.';
    Exit;
  end;

  if (LowerCase(Tipo) <> 'prioritario') and
     (LowerCase(Tipo) <> 'normal') then
  begin
    Msg := 'Categoria de atendimento inválida.';
    Exit;
  end;

  Prior := LowerCase(Tipo) = 'prioritario';
  K := -1;

  for I := 0 to High(FPacientes) do
    if (FPacientes[I].Situacao = 'Aguardando') and
       (FPacientes[I].Prioritario = Prior) then
    begin
      K := I;
      Break;
    end;

  if K < 0 then
  begin
    Msg := 'Não há pacientes aguardando nessa categoria.';
    Exit;
  end;

  FPacientes[K].Situacao := 'Em atendimento';
  FPacientes[K].ConsultorioId := FSalas[J].Id;
  FSalas[J].Ocupado := True;
  FSalas[J].PacienteId := FPacientes[K].Id;

  Salvar;
  Result := FPacientes[K].ToJSON;
  Msg := 'Senha ' + FPacientes[K].Senha +
    ' chamada para ' + FSalas[J].Sala + '.';
end;

// Finaliza o atendimento e deixa o consultório disponível novamente.
function TClinicaRepository.Finalizar(
  AConsultorioId: Integer;
  out Msg: string
): Boolean;
var
  J, K: Integer;
begin
  Result := False;
  J := IndiceSala(AConsultorioId);

  if J < 0 then
  begin
    Msg := 'Consultório não encontrado.';
    Exit;
  end;

  if not FSalas[J].Ocupado then
  begin
    Msg := 'Esse consultório não está em atendimento.';
    Exit;
  end;

  K := IndicePaciente(FSalas[J].PacienteId);

  if K >= 0 then
  begin
    FPacientes[K].Situacao := 'Atendido';
    FPacientes[K].ConsultorioId := 0;
  end;

  FSalas[J].Ocupado := False;
  FSalas[J].PacienteId := 0;

  Salvar;
  Msg := 'Atendimento finalizado; consultório liberado.';
  Result := True;
end;

// Atualiza os dados de um paciente que não esteja em atendimento.
function TClinicaRepository.EditarPaciente(
  AId: Integer;
  const Nome, CPF, Telefone: string;
  Idade: Integer;
  out Msg: string
): TJSONObject;
var
  K, Outro: Integer;
  NomeNovo, CPFNovo, TelefoneNovo: string;
begin
  Result := nil;
  K := IndicePaciente(AId);

  if K < 0 then
  begin
    Msg := 'Paciente não encontrado.';
    Exit;
  end;

  if FPacientes[K].Situacao = 'Em atendimento' then
  begin
    Msg := 'Não é possível editar durante o atendimento.';
    Exit;
  end;

  NomeNovo := Trim(Nome);
  CPFNovo := Trim(CPF);
  TelefoneNovo := Trim(Telefone);

  if NomeNovo = '' then
  begin
    Msg := 'Informe o nome.';
    Exit;
  end;

  if Length(CPFNovo) <> 11 then
  begin
    Msg := 'Informe o CPF com exatamente 11 dígitos.';
    Exit;
  end;

  Outro := IndiceCPF(CPFNovo);

  if (Outro >= 0) and (Outro <> K) then
  begin
    Msg := 'Já existe outro paciente com esse CPF.';
    Exit;
  end;

  if (Idade < 0) or (Idade > 120) then
  begin
    Msg := 'Idade deve estar entre 0 e 120.';
    Exit;
  end;

  FPacientes[K].Nome := NomeNovo;
  FPacientes[K].CPF := CPFNovo;
  FPacientes[K].Telefone := TelefoneNovo;
  FPacientes[K].Idade := Idade;
  FPacientes[K].Prioritario := Idade >= 60;

  Salvar;
  Result := FPacientes[K].ToJSON;
  Msg := 'Dados do paciente atualizados.';
end;

// Remove um paciente que não esteja sendo atendido.
function TClinicaRepository.RemoverPaciente(
  AId: Integer;
  out Msg: string
): Boolean;
var
  K, I: Integer;
begin
  Result := False;
  K := IndicePaciente(AId);

  if K < 0 then
  begin
    Msg := 'Paciente não encontrado.';
    Exit;
  end;

  if FPacientes[K].Situacao = 'Em atendimento' then
  begin
    Msg := 'Não é possível remover paciente em atendimento.';
    Exit;
  end;

  FPacientes[K].Free;

  for I := K to High(FPacientes) - 1 do
    FPacientes[I] := FPacientes[I + 1];

  SetLength(FPacientes, Length(FPacientes) - 1);

  Salvar;
  Msg := 'Paciente removido.';
  Result := True;
end;

end.
