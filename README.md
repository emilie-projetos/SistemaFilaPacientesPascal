
# Sistema de Fila de Pacientes

Sistema acadêmico de gerenciamento de filas de atendimento,
desenvolvido em Free Pascal (Object Pascal), com interface web.

## Funcionalidades

- Cadastro de pacientes.
- Edição dos dados cadastrais por janela modal.
- Remoção de pacientes que aguardam atendimento.
- Busca por nome, CPF, senha ou situação.
- Geração de senhas sequenciais por categoria.
- Prioridade automática para pacientes com 60 anos ou mais.
- Cadastro de profissionais e consultórios.
- Chamada de pacientes prioritários ou normais.
- Controle de ocupação dos consultórios.
- Finalização de atendimentos.
- Persistência local em arquivo JSON.

## Tecnologias

- Free Pascal / Object Pascal.
- HTML5.
- CSS3.
- JavaScript.
- API HTTP.
- JSON.

## Requisitos

- Free Pascal Compiler (FPC) compatível com o projeto.
- Unidade `fphttpserver` disponível no ambiente FPC.
- Navegador atualizado.

## Estrutura do projeto

```text
SistemaFilaPacientesPascal/
├── ProjetoCadastroClientes.lpr
├── Servidor.pas
├── PacienteModel.pas
├── ClinicaRepository.pas
├── README.md
├── .gitignore
├── dados/
│   └── LEIA.txt
└── www/
    ├── index.html
    ├── style.css
    └── app.js
```

O arquivo `dados/fila.json` é criado ou atualizado pelo sistema.
Ele deve permanecer local e não deve conter dados pessoais no Git.

## Compilação

Abra o terminal na pasta principal do projeto e execute:

```bash
fpc ProjetoCadastroClientes.lpr
```

O compilador precisa estar instalado e disponível no PATH.

## Execução

No Windows:

```powershell
.\ProjetoCadastroClientes.exe
```

No Linux, após compilar:

```bash
./ProjetoCadastroClientes
```

Abra no navegador:

http://localhost:8080

Mantenha o terminal aberto enquanto estiver utilizando o sistema.
Encerre o processo quando terminar.

## Persistência

Os dados são armazenados localmente em `dados/fila.json`.

Faça cópias de segurança quando necessário.
Não publique arquivos que contenham dados reais de pacientes.

## Segurança

Esta versão é destinada a desenvolvimento e demonstração local.

Antes de qualquer utilização com dados reais, implemente e valide:

- Autenticação e autorização.
- Controle de acesso por perfil.
- Proteção dos dados pessoais e de saúde.
- Política de backups e recuperação.
- Registro de operações relevantes.
- Proteção contra acesso remoto indevido.
- Validação completa dos dados recebidos pela API.

O fato de o servidor estar limitado ao uso local não substitui essas
medidas quando houver utilização de dados reais.













# Como executar o Sistema de Fila de Pacientes

Este guia explica como instalar os requisitos, compilar e executar o Sistema de Fila de Pacientes desenvolvido em Free Pascal (Object Pascal), com interface web em HTML, CSS e JavaScript.

## 1. Requisitos

Antes de começar, você precisa ter instalado:

- Free Pascal Compiler (FPC)
- Um navegador web atualizado, como Google Chrome, Microsoft Edge ou Firefox.
- Um terminal de comandos.
- Git, caso queira clonar o projeto do GitHub.

## 2. Baixar o projeto

### Opção A — Clonar pelo Git

Abra o terminal e execute:

```bash
git clone URL_DO_SEU_REPOSITORIO
```

Entre na pasta do projeto:

```bash
cd SistemaFilaPacientesPascal
```

**Importante:** substitua `URL_DO_SEU_REPOSITORIO` pelo endereço real do seu repositório no GitHub.

### Opção B — Utilizar o projeto já baixado

Se você já baixou ou extraiu o projeto, abra o terminal e entre na pasta onde está localizado o arquivo `ProjetoCadastroClientes.lpr`.

Por exemplo, no Windows:

```powershell
cd "C:\caminho\para\SistemaFilaPacientesPascal"
```

No Linux:

```bash
cd /caminho/para/SistemaFilaPacientesPascal
```

## 3. Verificar a instalação do Free Pascal

No terminal, execute:

```bash
fpc -iV
```

Se o compilador estiver instalado e configurado corretamente, será exibida a versão do Free Pascal.

Se aparecer uma mensagem informando que o comando não foi encontrado, instale o Free Pascal e configure o PATH do sistema operacional.

## 4. Conferir a estrutura dos arquivos

A pasta principal deverá conter os arquivos do backend e as pastas da interface web.

```text
SistemaFilaPacientesPascal/
├── ProjetoCadastroClientes.lpr
├── Servidor.pas
├── PacienteModel.pas
├── ClinicaRepository.pas
├── dados/
└── www/
    ├── index.html
    ├── style.css
    └── app.js
```

O arquivo `ProjetoCadastroClientes.lpr` é o ponto de entrada do programa.

Os arquivos `.pas` contêm a lógica do sistema, enquanto a pasta `www` contém a interface web.

## 5. Compilar o projeto

Com o terminal aberto na pasta principal do projeto, execute:

```bash
fpc ProjetoCadastroClientes.lpr
```

O compilador deverá processar o arquivo principal e suas unidades dependentes.

Se a compilação terminar sem erros, será gerado um executável, normalmente chamado `ProjetoCadastroClientes.exe` no Windows ou `ProjetoCadastroClientes` no Linux.

Os arquivos `.o` e `.ppu` gerados durante a compilação são arquivos auxiliares e não precisam ser enviados ao GitHub.

**Se ocorrer um erro de compilação:** confira a mensagem apresentada pelo FPC, a versão instalada e a disponibilidade das unidades necessárias, especialmente `fphttpserver`, `httpdefs`, `fpjson` e `jsonparser`.

## 6. Executar no Windows

Depois de compilar o projeto, execute no PowerShell:

```powershell
.\ProjetoCadastroClientes.exe
```

Se estiver utilizando o Prompt de Comando (CMD), execute:

```cmd
ProjetoCadastroClientes.exe
```

Mantenha o terminal aberto enquanto o sistema estiver em execução.

## 7. Executar no Linux

Depois de compilar, execute:

```bash
./ProjetoCadastroClientes
```

Se necessário, conceda permissão de execução:

```bash
chmod +x ProjetoCadastroClientes
```

Em seguida, execute novamente o programa.

## 8. Abrir a interface no navegador

Com o servidor iniciado, abra o navegador e acesse:

http://localhost:8080

A interface web deverá ser carregada pelo próprio servidor.

A partir dela, será possível utilizar as funcionalidades implementadas, como cadastro de pacientes, gerenciamento de consultórios, chamada de pacientes e finalização de atendimentos.

Não feche o terminal enquanto estiver utilizando o sistema.

## 9. Onde os dados são armazenados

Os dados são armazenados localmente no arquivo:

```text
dados/fila.json
```

Esse arquivo é utilizado para persistir os registros entre execuções.

Não publique dados reais de pacientes no GitHub. O arquivo deve ser mantido localmente ou conter exclusivamente dados fictícios para demonstração.

## 10. Como encerrar o sistema

Para interromper o servidor, volte ao terminal em que o programa está sendo executado e pressione:

```text
Ctrl + C
```

## 11. Solução de problemas

### O comando `fpc` não é reconhecido

Verifique se o Free Pascal está instalado e se o diretório do compilador foi adicionado ao PATH.

### A compilação apresenta erros

Confira se todos os arquivos `.pas` necessários estão presentes e se as unidades utilizadas pelo projeto estão instaladas.

### O navegador não abre a interface

Verifique se o programa está em execução e se a porta `8080` está disponível.

### A interface abre, mas as operações falham

Confira as mensagens do terminal, a disponibilidade do arquivo de dados e se os endpoints da API correspondem aos utilizados pelo JavaScript.

### O sistema não encontra os arquivos da interface

Execute o programa com a estrutura de diretórios esperada, mantendo a pasta `www` ao lado do executável e o diretório `dados` na pasta do projeto.

## 12. Aviso de segurança

Esta aplicação é destinada a desenvolvimento e demonstração local.

Antes de utilizá-la com dados reais, implemente e teste mecanismos de autenticação, autorização, proteção dos dados pessoais e de saúde, backups e controle de acesso.

Não exponha o servidor diretamente à internet sem uma revisão de segurança adequada.

