import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/formatacao.dart';
import '../../../core/validadores.dart';
import '../../../data/modelos.dart';
import '../../../data/perfil_repositorio.dart';
import '../../../state/sessao.dart';
import '../../widgets/comuns.dart';
import '../instrutor/perfil_profissional_tela.dart';
import 'endereco_tela.dart';

/// Dados pessoais (nome, telefone, cidade) de aluno e instrutor, e saída da conta.
class PerfilTela extends StatefulWidget {
  const PerfilTela({super.key});

  @override
  State<PerfilTela> createState() => _PerfilTelaState();
}

class _PerfilTelaState extends State<PerfilTela> {
  final _form = GlobalKey<FormState>();
  late final Perfil _perfil = context.read<Sessao>().perfil!;
  late final _nome = TextEditingController(text: _perfil.nome);
  late final _telefone = TextEditingController(text: formatarTelefone(_perfil.telefone));
  late int? _cidadeId = _perfil.cidadeId;
  late final Future<List<Cidade>> _cidades = context.read<PerfilRepositorio>().cidadesEmCache();
  bool _ocupado = false;

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _ocupado = true);
    try {
      final telefone = somenteDigitos(_telefone.text);
      final perfil = await context.read<PerfilRepositorio>().atualizar(
            _perfil.id,
            nome: _nome.text.trim(),
            telefone: telefone.isEmpty ? null : telefone,
            cidadeId: _cidadeId,
          );
      if (!mounted) return;
      context.read<Sessao>().perfilAtualizado(perfil);
      mostrarMensagem(context, 'Perfil salvo.');
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _sair() async {
    final ok = await confirmar(context, titulo: 'Sair da conta?', mensagem: 'Você precisará entrar de novo.', confirmarTexto: 'Sair');
    if (ok && mounted) await context.read<Sessao>().sair();
  }

  @override
  Widget build(BuildContext context) {
    final sessao = context.read<Sessao>();
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.account_circle, size: 40),
              title: Text(sessao.email),
              subtitle: Text(_perfil.ehInstrutor ? 'Conta de instrutor' : 'Conta de aluno'),
            ),
            const Secao('Dados pessoais'),
            TextFormField(
              controller: _nome,
              decoration: const InputDecoration(labelText: 'Nome'),
              textCapitalization: TextCapitalization.words,
              validator: validarNome,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefone,
              decoration: const InputDecoration(
                labelText: 'Telefone com DDD (opcional)',
                hintText: '(11) 98765-4321',
              ),
              keyboardType: TextInputType.phone,
              validator: validarTelefone,
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Cidade>>(
              future: _cidades,
              builder: (context, snap) => DropdownButtonFormField<int?>(
                initialValue: _cidadeId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Cidade',
                  errorText: snap.hasError ? mensagemDe(snap.error!) : null,
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Não informada')),
                  for (final c in snap.data ?? const <Cidade>[])
                    DropdownMenuItem(value: c.id, child: Text(c.toString())),
                ],
                onChanged: (v) => _cidadeId = v,
              ),
            ),
            const SizedBox(height: 16),
            BotaoAcao(texto: 'Salvar', ocupado: _ocupado, aoPressionar: _salvar),
            const Secao('Mais'),
            Card(
              child: Column(children: [
                if (_perfil.ehInstrutor)
                  ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: const Text('Perfil profissional'),
                    subtitle: const Text('Categorias, veículo, cidade e taxa de busca'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PerfilProfissionalTela()),
                    ),
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.home_outlined),
                    title: const Text('Meu endereço'),
                    subtitle: const Text('Usado quando você pede para ser buscado'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EnderecoTela()),
                    ),
                  ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                  title: const Text('Sair'),
                  onTap: _sair,
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
