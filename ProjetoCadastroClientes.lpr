
program SistemaFilaPacientes;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX} cthreads, {$ENDIF}
  Classes, SysUtils, Servidor;

var
  App: TServidorCadastro;
  BaseDir: string;

begin
  // Identifica a pasta onde o executável está localizado.
  BaseDir := IncludeTrailingPathDelimiter(
    ExtractFilePath(ExpandFileName(ParamStr(0)))
  );

  // Cria o servidor na porta 8080.
  App := TServidorCadastro.Create(8080, BaseDir);

  try
    // Inicia o atendimento das requisições HTTP.
    App.Iniciar;
  finally
    // Libera o servidor mesmo se ocorrer uma exceção.
    App.Free;
  end;
end.
