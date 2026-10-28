
// Guarda os pacientes e consultórios carregados da API.
let pacientes = [];
let salas = [];

// Localiza um elemento HTML pelo seu identificador.
function $(id) {
  return document.getElementById(id);
}

// Exibe uma mensagem de sucesso ou erro por alguns segundos.
function msg(texto, erro = false) {
  const elemento = $('msg');

  elemento.textContent = texto;
  elemento.className = 'msg' + (erro ? ' error' : '');

  window.clearTimeout(msg.timer);

  msg.timer = window.setTimeout(() => {
    elemento.classList.add('hidden');
  }, 5000);
}

// Escapa caracteres especiais antes de inserir texto em HTML.
function esc(valor) {
  return String(valor ?? '').replace(/[&<>"']/g, caractere => ({
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#39;'
  })[caractere]);
}

// Envia uma requisição à API e transforma respostas inválidas em erros.
async function api(url, opcoes = {}) {
  const resposta = await fetch(url, {
    ...opcoes,
    headers: {
      'Content-Type': 'application/json',
      ...(opcoes.headers || {})
    }
  });

  let dados = {};

  try {
    dados = await resposta.json();
  } catch {
    dados = {};
  }

  if (!resposta.ok) {
    throw new Error(
      dados.erro || `Falha na operação (HTTP ${resposta.status}).`
    );
  }

  return dados;
}

// Carrega pacientes e consultórios e atualiza a interface.
async function carregar() {
  try {
    const resultado = await Promise.all([
      api('/api/pacientes'),
      api('/api/consultorios')
    ]);

    pacientes = resultado[0];
    salas = resultado[1];

    render();
  } catch (erro) {
    msg(
      'Não foi possível carregar os dados. Verifique se o servidor está ativo. ' +
      erro.message,
      true
    );
  }
}

// Atualiza os indicadores, a tabela de pacientes e os consultórios.
function render() {
  const aguardando = pacientes.filter(
    paciente => paciente.situacao === 'Aguardando'
  );

  const atendimento = pacientes.filter(
    paciente => paciente.situacao === 'Em atendimento'
  );

  const finalizados = pacientes.filter(
    paciente => paciente.situacao === 'Atendido'
  );

  $('aguardando').textContent = aguardando.length;
  $('emAtendimento').textContent = atendimento.length;
  $('finalizados').textContent = finalizados.length;

  const termo = $('busca').value.toLocaleLowerCase('pt-BR');

  // Ordena os prioritários primeiro e preserva a ordem de cadastro.
  const ordenados = [...pacientes]
    .sort((a, b) =>
      Number(b.prioritario) - Number(a.prioritario) || a.id - b.id
    )
    .filter(paciente =>
      [
        paciente.nome,
        paciente.cpf,
        paciente.senha,
        paciente.situacao
      ].some(valor =>
        String(valor ?? '').toLocaleLowerCase('pt-BR').includes(termo)
      )
    );

  // Monta as linhas da tabela com os dados escapados.
  $('pacientes').innerHTML = ordenados.length
    ? ordenados.map(paciente => {
        const sala = salas.find(
          item => item.id === paciente.consultorioId
        );

        let botoes = '';

        if (paciente.situacao === 'Em atendimento') {
          botoes =
            `<button type="button" class="smallbtn"
              data-finalizar="${paciente.consultorioId}">
              Finalizar
            </button>`;
        } else {
          botoes =
            `<button type="button" class="smallbtn"
              data-edit="${paciente.id}">
              Editar
            </button>`;

          if (paciente.situacao === 'Aguardando') {
            botoes +=
              ` <button type="button" class="smallbtn"
                data-remove="${paciente.id}">
                Remover
              </button>`;
          }
        }

        const classeSituacao =
          paciente.situacao === 'Atendido'
            ? 'done'
            : paciente.situacao === 'Em atendimento'
              ? 'busy'
              : '';

        return `
          <tr>
            <td><strong>${esc(paciente.senha)}</strong></td>
            <td>
              ${esc(paciente.nome)}
              <small style="display:block;color:#74818a">
                ${esc(paciente.cpf)}
              </small>
            </td>
            <td>${paciente.idade}</td>
            <td>
              <span class="pill ${paciente.prioritario ? 'prio' : ''}">
                ${paciente.prioritario ? 'Prioritário' : 'Normal'}
              </span>
            </td>
            <td>
              <span class="pill ${classeSituacao}">
                ${esc(paciente.situacao)}
              </span>
            </td>
            <td>${esc(sala ? sala.sala : '—')}</td>
            <td>${botoes}</td>
          </tr>
        `;
      }).join('')
    : '<tr><td colspan="7">Nenhum paciente encontrado.</td></tr>';

  // Atualiza os cartões de ocupação dos consultórios.
  $('salas').innerHTML = salas.length
    ? salas.map(sala => `
        <div class="room">
          <div>
            <strong>${esc(sala.sala)}</strong>
            <small>
              ${esc(sala.profissional)}
              ${sala.pacienteNome
                ? ' • ' + esc(sala.pacienteNome)
                : ''}
            </small>
          </div>
          <span class="pill ${sala.ocupado ? 'busy' : 'done'}">
            ${sala.ocupado ? 'Ocupado' : 'Livre'}
          </span>
        </div>
      `).join('')
    : '<p>Nenhum consultório cadastrado.</p>';
}

// Retira caracteres que não sejam números de um CPF digitado.
function normalizarCPF(valor) {
  return valor.replace(/\D/g, '');
}

// Envia o formulário de cadastro e exibe a senha gerada.
$('pacienteForm').addEventListener('submit', async evento => {
  evento.preventDefault();

  try {
    const paciente = await api('/api/pacientes', {
      method: 'POST',
      body: JSON.stringify({
        nome: $('nome').value.trim(),
        idade: Number($('idade').value),
        cpf: normalizarCPF($('cpf').value),
        telefone: $('telefone').value.trim()
      })
    });

    $('pacienteForm').reset();

    msg(`Paciente cadastrado! Senha gerada: ${paciente.senha}`);

    await carregar();
  } catch (erro) {
    msg(erro.message, true);
  }
});

// Envia o formulário de cadastro de profissional e consultório.
$('salaForm').addEventListener('submit', async evento => {
  evento.preventDefault();

  try {
    await api('/api/consultorios', {
      method: 'POST',
      body: JSON.stringify({
        profissional: $('profissional').value.trim(),
        sala: $('sala').value.trim()
      })
    });

    $('salaForm').reset();

    msg('Consultório cadastrado.');

    await carregar();
  } catch (erro) {
    msg(erro.message, true);
  }
});

// Solicita ao backend a chamada da categoria selecionada.
async function chamar(tipo) {
  try {
    const paciente = await api('/api/chamar', {
      method: 'POST',
      body: JSON.stringify({ tipo })
    });

    msg(`Chamando ${paciente.senha} — ${paciente.nome}`);

    await carregar();
  } catch (erro) {
    msg(erro.message, true);
  }
}

// Associa os botões de chamada às respectivas categorias.
$('chamarPrioritario').addEventListener('click', () => {
  chamar('prioritario');
});

$('chamarNormal').addEventListener('click', () => {
  chamar('normal');
});

// Abre o modal e preenche os campos com os dados do paciente.
function abrirEdicao(id) {
  const paciente = pacientes.find(
    item => item.id === Number(id)
  );

  if (!paciente) {
    msg('Paciente não encontrado na lista atualizada.', true);
    return;
  }

  if (paciente.situacao === 'Em atendimento') {
    msg('Não é possível editar durante o atendimento.', true);
    return;
  }

  $('editId').value = paciente.id;
  $('editNome').value = paciente.nome || '';
  $('editIdade').value = paciente.idade ?? 0;
  $('editCpf').value = paciente.cpf || '';
  $('editTelefone').value = paciente.telefone || '';

  $('editModal').classList.remove('hidden');
  $('editNome').focus();
}

// Fecha o modal de edição e devolve o foco à página.
function fecharEdicao() {
  $('editModal').classList.add('hidden');
}

// Trata os botões de editar, remover e finalizar da tabela.
$('pacientes').addEventListener('click', async evento => {
  const botao = evento.target.closest('button');

  if (!botao) {
    return;
  }

  try {
    if (botao.dataset.edit) {
      abrirEdicao(botao.dataset.edit);
      return;
    }

    if (botao.dataset.remove) {
      const confirmado = window.confirm(
        'Remover este paciente da fila?'
      );

      if (!confirmado) {
        return;
      }

      await api('/api/pacientes/' + botao.dataset.remove, {
        method: 'DELETE'
      });

      msg('Paciente removido.');
      await carregar();
      return;
    }

    if (botao.dataset.finalizar) {
      await api('/api/finalizar/' + botao.dataset.finalizar, {
        method: 'POST'
      });

      msg('Atendimento finalizado e consultório liberado.');
      await carregar();
    }
  } catch (erro) {
    msg(erro.message, true);
  }
});

// Atualiza a tabela enquanto o usuário digita na busca.
$('busca').addEventListener('input', render);

// Fecha o modal ao clicar no botão Cancelar.
$('cancelarEdicao').addEventListener('click', fecharEdicao);

// Fecha o modal ao clicar fora do cartão de edição.
$('editModal').addEventListener('click', evento => {
  if (evento.target === $('editModal')) {
    fecharEdicao();
  }
});

// Envia as alterações do paciente para o backend.
$('editForm').addEventListener('submit', async evento => {
  evento.preventDefault();

  try {
    const id = Number($('editId').value);

    await api('/api/pacientes/' + id, {
      method: 'PUT',
      body: JSON.stringify({
        nome: $('editNome').value.trim(),
        idade: Number($('editIdade').value),
        cpf: normalizarCPF($('editCpf').value),
        telefone: $('editTelefone').value.trim()
      })
    });

    fecharEdicao();
    msg('Dados do paciente atualizados.');

    await carregar();
  } catch (erro) {
    msg(erro.message, true);
  }
});

// Carrega os dados iniciais assim que o script é executado.
carregar();
