
unit Servidor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphttpserver, httpdefs, fpjson, jsonparser,
  ClinicaRepository;

type
  TServidorCadastro = class
  private
    FHTTP: TFPHTTPServer;
    FRepo: TClinicaRepository;
    FBase: string;

    // Direciona cada requisição HTTP para a rota correta.
    procedure Requisicao(
      Sender: TObject;
      var Req: TFPHTTPConnectionRequest;
      var Res: TFPHTTPConnectionResponse
    );

    // Envia uma resposta JSON com o código HTTP informado.
    procedure JSON(
      var Res: TFPHTTPConnectionResponse;
      Codigo: Integer;
      D: TJSONData
    );

    // Lê um campo textual de um objeto JSON.
    function Texto(O: TJSONObject; const N: string): string;

    // Lê um campo numérico de um objeto JSON.
    function Inteiro(O: TJSONObject; const N: string): Integer;

    // Converte um texto JSON em objeto, tratando conteúdo inválido.
    function LerObjeto(const S: string): TJSONObject;

    // Localiza e envia um arquivo estático da interface.
    procedure Arquivo(
      const Nome: string;
      var Res: TFPHTTPConnectionResponse
    );

  public
    // Cria o servidor e inicializa o repositório.
    constructor Create(Porta: Word; const BaseDir: string);

    // Encerra o servidor e libera os recursos utilizados.
    destructor Destroy; override;

    // Inicia o servidor HTTP.
    procedure Iniciar;
  end;

implementation

// Inicializa o servidor HTTP e carrega os dados da clínica.
constructor TServidorCadastro.Create(
  Porta: Word;
  const BaseDir: string
);
begin
  inherited Create;

  FBase := IncludeTrailingPathDelimiter(BaseDir);

  FRepo := TClinicaRepository.Create(
    FBase + 'dados' + PathDelim + 'fila.json'
  );

  FHTTP := TFPHTTPServer.Create(nil);
  FHTTP.Port := Porta;

  // Processamento sequencial para proteger o repositório em memória.
  FHTTP.Threaded := False;

  FHTTP.OnRequest := @Requisicao;
end;

// Desliga o servidor e libera os objetos associados.
destructor TServidorCadastro.Destroy;
begin
  FHTTP.Active := False;
  FHTTP.Free;
  FRepo.Free;

  inherited Destroy;
end;

// Retorna um campo textual ou uma string vazia.
function TServidorCadastro.Texto(
  O: TJSONObject;
  const N: string
): string;
begin
  Result := O.Get(N, '');
end;

// Retorna um campo numérico ou zero.
function TServidorCadastro.Inteiro(
  O: TJSONObject;
  const N: string
): Integer;
begin
  Result := O.Get(N, 0);
end;

// Lê um objeto JSON e devolve nil quando o conteúdo é inválido.
function TServidorCadastro.LerObjeto(
  const S: string
): TJSONObject;
var
  D: TJSONData;
begin
  Result := nil;
  D := nil;

  try
    D := GetJSON(S);

    if D.JSONType = jtObject then
    begin
      Result := TJSONObject(D);
      D := nil;
    end;
  except
    Result := nil;
  end;

  D.Free;
end;

// Define o status HTTP, o tipo de conteúdo e o corpo da resposta.
procedure TServidorCadastro.JSON(
  var Res: TFPHTTPConnectionResponse;
  Codigo: Integer;
  D: TJSONData
);
begin
  Res.Code := Codigo;
  Res.ContentType := 'application/json; charset=utf-8';

  if D <> nil then
    Res.Content := D.AsJSON
  else
    Res.Content := '{}';
end;

// Serve HTML, CSS e JavaScript armazenados na pasta www.
procedure TServidorCadastro.Arquivo(
  const Nome: string;
  var Res: TFPHTTPConnectionResponse
);
var
  L: TStringList;
  P: string;
begin
  P := FBase + 'www' + PathDelim + Nome;

  if not FileExists(P) then
  begin
    Res.Code := 404;
    Res.ContentType := 'text/plain; charset=utf-8';
    Res.Content := 'Arquivo não encontrado.';
    Exit;
  end;

  L := TStringList.Create;
  try
    L.LoadFromFile(P);

    Res.Code := 200;
    Res.Content := L.Text;

    if ExtractFileExt(P) = '.css' then
      Res.ContentType := 'text/css; charset=utf-8'
    else if ExtractFileExt(P) = '.js' then
      Res.ContentType := 'application/javascript; charset=utf-8'
    else
      Res.ContentType := 'text/html; charset=utf-8';
  finally
    L.Free;
  end;
end;

// Interpreta as rotas da API e encaminha as operações ao repositório.
procedure TServidorCadastro.Requisicao(
  Sender: TObject;
  var Req: TFPHTTPConnectionRequest;
  var Res: TFPHTTPConnectionResponse
);
var
  P, Msg, Tipo: string;
  O: TJSONObject;
  D: TJSONData;
  B: Boolean;
  Id: Integer;
begin
  P := Req.URI;

  // Remove parâmetros da URL antes de identificar a rota.
  if Pos('?', P) > 0 then
    P := Copy(P, 1, Pos('?', P) - 1);

  // Responde a requisições OPTIONS sem habilitar CORS público.
  if Req.Method = 'OPTIONS' then
  begin
    Res.Code := 204;
    Res.Content := '';
    Exit;
  end;

  // Entrega a interface web.
  if (P = '/') or (P = '/index.html') then
  begin
    Arquivo('index.html', Res);
    Exit;
  end;

  if P = '/style.css' then
  begin
    Arquivo('style.css', Res);
    Exit;
  end;

  if P = '/app.js' then
  begin
    Arquivo('app.js', Res);
    Exit;
  end;

  // GET /api/pacientes: lista os pacientes cadastrados.
  if (P = '/api/pacientes') and (Req.Method = 'GET') then
  begin
    D := FRepo.ListarPacientes;
    try
      JSON(Res, 200, D);
    finally
      D.Free;
    end;
    Exit;
  end;

  // GET /api/consultorios: lista os consultórios.
  if (P = '/api/consultorios') and (Req.Method = 'GET') then
  begin
    D := FRepo.ListarSalas;
    try
      JSON(Res, 200, D);
    finally
      D.Free;
    end;
    Exit;
  end;

  // POST /api/pacientes: cadastra um novo paciente.
  if (P = '/api/pacientes') and (Req.Method = 'POST') then
  begin
    O := LerObjeto(Req.Content);

    if O = nil then
    begin
      O := TJSONObject.Create;
      O.Add('erro', 'JSON inválido.');
      JSON(Res, 400, O);
      O.Free;
      Exit;
    end;

    try
      D := FRepo.CadastrarPaciente(
        Texto(O, 'nome'),
        Texto(O, 'cpf'),
        Texto(O, 'telefone'),
        Inteiro(O, 'idade'),
        Msg
      );
    finally
      O.Free;
    end;

    if D = nil then
    begin
      O := TJSONObject.Create;
      O.Add('erro', Msg);
      JSON(Res, 400, O);
      O.Free;
    end
    else
    begin
      JSON(Res, 201, D);
      D.Free;
    end;
    Exit;
  end;

  // POST /api/consultorios: cadastra um profissional e consultório.
  if (P = '/api/consultorios') and (Req.Method = 'POST') then
  begin
    O := LerObjeto(Req.Content);

    if O = nil then
    begin
      O := TJSONObject.Create;
      O.Add('erro', 'JSON inválido.');
      JSON(Res, 400, O);
      O.Free;
      Exit;
    end;

    try
      D := FRepo.CadastrarSala(
        Texto(O, 'profissional'),
        Texto(O, 'sala'),
        Msg
      );
    finally
      O.Free;
    end;

    if D = nil then
    begin
      O := TJSONObject.Create;
      O.Add('erro', Msg);
      JSON(Res, 400, O);
      O.Free;
    end
    else
    begin
      JSON(Res, 201, D);
      D.Free;
    end;
    Exit;
  end;

  // POST /api/chamar: chama um paciente prioritário ou normal.
  if (P = '/api/chamar') and (Req.Method = 'POST') then
  begin
    O := LerObjeto(Req.Content);

    if O = nil then
    begin
      O := TJSONObject.Create;
      O.Add('erro', 'JSON inválido.');
      JSON(Res, 400, O);
      O.Free;
      Exit;
    end;

    try
      Tipo := Texto(O, 'tipo');
      D := FRepo.ChamarProximo(Tipo, Msg);
    finally
      O.Free;
    end;

    if D = nil then
    begin
      O := TJSONObject.Create;
      O.Add('erro', Msg);
      JSON(Res, 400, O);
      O.Free;
    end
    else
    begin
      JSON(Res, 200, D);
      D.Free;
    end;
    Exit;
  end;

  // POST /api/finalizar/{id}: encerra o atendimento do consultório.
  if Copy(P, 1, 15) = '/api/finalizar/' then
  begin
    if Req.Method <> 'POST' then
    begin
      O := TJSONObject.Create;
      O.Add('erro', 'Método HTTP não permitido.');
      JSON(Res, 405, O);
      O.Free;
      Exit;
    end;

    Id := StrToIntDef(Copy(P, 16, MaxInt), 0);

    if Id <= 0 then
    begin
      O := TJSONObject.Create;
      O.Add('erro', 'Identificador de consultório inválido.');
      JSON(Res, 400, O);
      O.Free;
      Exit;
    end;

    B := FRepo.Finalizar(Id, Msg);
    O := TJSONObject.Create;

    if B then
      O.Add('mensagem', Msg)
    else
      O.Add('erro', Msg);

    if B then
      JSON(Res, 200, O)
    else
      JSON(Res, 400, O);

    O.Free;
    Exit;
  end;

  // PUT ou DELETE /api/pacientes/{id}: edita ou remove um paciente.
  if Copy(P, 1, 15) = '/api/pacientes/' then
  begin
    Id := StrToIntDef(Copy(P, 16, MaxInt), 0);

    if Id <= 0 then
    begin
      O := TJSONObject.Create;
      O.Add('erro', 'Identificador de paciente inválido.');
      JSON(Res, 400, O);
      O.Free;
      Exit;
    end;

    // Atualiza os dados cadastrais.
    if Req.Method = 'PUT' then
    begin
      O := LerObjeto(Req.Content);

      if O = nil then
      begin
        O := TJSONObject.Create;
        O.Add('erro', 'JSON inválido.');
        JSON(Res, 400, O);
        O.Free;
        Exit;
      end;

      try
        D := FRepo.EditarPaciente(
          Id,
          Texto(O, 'nome'),
          Texto(O, 'cpf'),
          Texto(O, 'telefone'),
          Inteiro(O, 'idade'),
          Msg
        );
      finally
        O.Free;
      end;

      if D = nil then
      begin
        O := TJSONObject.Create;
        O.Add('erro', Msg);
        JSON(Res, 400, O);
        O.Free;
      end
      else
      begin
        JSON(Res, 200, D);
        D.Free;
      end;
      Exit;
    end;

    // Remove um paciente que ainda não esteja em atendimento.
    if Req.Method = 'DELETE' then
    begin
      B := FRepo.RemoverPaciente(Id, Msg);
      O := TJSONObject.Create;

      if B then
        O.Add('mensagem', Msg)
      else
        O.Add('erro', Msg);

      if B then
        JSON(Res, 200, O)
      else
        JSON(Res, 400, O);

      O.Free;
      Exit;
    end;
  end;

  // Retorna erro quando a rota não existe ou o método não é aceito.
  O := TJSONObject.Create;
  O.Add('erro', 'Rota não encontrada.');
  JSON(Res, 404, O);
  O.Free;
end;

// Exibe as instruções e inicia o servidor HTTP.
procedure TServidorCadastro.Iniciar;
begin
  WriteLn('Sistema de Fila de Pacientes - Object Pascal');
  WriteLn('Abra: http://localhost:', FHTTP.Port);
  WriteLn('Encerre com Ctrl+C.');

  FHTTP.Active := True;
end;

end.
