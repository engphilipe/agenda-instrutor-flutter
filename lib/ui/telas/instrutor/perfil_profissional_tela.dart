import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/formatacao.dart';
import '../../../core/validadores.dart';
import '../../../data/agenda_repositorio.dart';
import '../../../data/modelos.dart';
import '../../../data/perfil_repositorio.dart';
import '../../../state/sessao.dart';
import '../../widgets/comuns.dart';

/// Dados que aparecem para o aluno na busca e no perfil do instrutor.
class PerfilProfissionalTela extends StatelessWidget {
  const PerfilProfissionalTela({super.key});

  @override
  Widget build(BuildContext context) {
    final id = context.read<Sessao>().usuarioId;
    final agenda = context.read<AgendaRepositorio>();
    final perfis = context.read<PerfilRepositorio>();
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil profissional')),
      body: Carregador<(PerfilProfissional, List<Cidade>)>(
        carregar: () => (agenda.perfilProfissional(id), perfis.cidadesEmCache()).wait,
        construir: (context, dados, _) => _Formulario(dados.$1, dados.$2),
      ),
    );
  }
}

class _Formulario extends StatefulWidget {
  const _Formulario(this.perfil, this.cidades);

  final PerfilProfissional perfil;
  final List<Cidade> cidades;

  @override
  State<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<_Formulario> {
  final _form = GlobalKey<FormState>();
  late final p = widget.perfil;
  late final _categorias = {...p.categorias};
  late int? _cidadeId = p.cidadeId;
  late final _bio = TextEditingController(text: p.bio);
  late final _veiculo = TextEditingController(text: p.veiculo);
  late final _ponto = TextEditingController(text: p.pontoEncontro);
  late final _taxa = TextEditingController(
    text: p.taxaBuscaCentavos == null
        ? ''
        : (p.taxaBuscaCentavos! / 100).toStringAsFixed(2).replaceAll('.', ','),
  );
  late bool _ofereceBusca = p.ofereceBusca;
  late bool _ativo = p.ativo;
  bool _tentouEnviar = false;
  bool _ocupado = false;

  @override
  void dispose() {
    for (final c in [_bio, _veiculo, _ponto, _taxa]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() => _tentouEnviar = true);
    if (!_form.currentState!.validate() || _categorias.isEmpty) return;
    setState(() => _ocupado = true);
    try {
      await context.read<AgendaRepositorio>().salvarPerfilProfissional(
            context.read<Sessao>().usuarioId,
            categorias: _categorias.toList()..sort(),
            cidadeId: _cidadeId,
            bio: _bio.text,
            veiculo: _veiculo.text,
            pontoEncontro: _ponto.text,
            ofereceBusca: _ofereceBusca,
            taxaBuscaCentavos: _ofereceBusca ? reaisParaCentavos(_taxa.text) : null,
            ativo: _ativo,
          );
      if (!mounted) return;
      mostrarMensagem(context, 'Perfil profissional salvo.');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          Card(
            child: ListTile(
              leading: Icon(
                p.status == 'aprovado' ? Icons.verified : Icons.hourglass_top,
                color: p.status == 'aprovado' ? Colors.green : Colors.amber,
              ),
              title: Text(switch (p.status) {
                'aprovado' => 'Cadastro aprovado',
                'recusado' => 'Cadastro recusado',
                _ => 'Cadastro em análise',
              }),
              subtitle: Text(p.status == 'aprovado'
                  ? 'Você aparece na busca dos alunos.'
                  : 'Você aparece na busca depois da aprovação.'),
            ),
          ),
          const Secao('Categorias em que dá aula'),
          Wrap(spacing: 8, children: [
            for (final c in ['A', 'B'])
              FilterChip(
                label: Text(nomesCategoria[c]!),
                selected: _categorias.contains(c),
                onSelected: (sim) => setState(() => sim ? _categorias.add(c) : _categorias.remove(c)),
              ),
          ]),
          if (_tentouEnviar && _categorias.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Escolha ao menos uma categoria', style: TextStyle(color: cores.error)),
            ),
          const Secao('Sobre'),
          DropdownButtonFormField<int>(
            initialValue: _cidadeId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Cidade onde atende'),
            items: [
              for (final c in widget.cidades) DropdownMenuItem(value: c.id, child: Text(c.toString())),
            ],
            onChanged: (v) => _cidadeId = v,
            validator: (v) => v == null ? 'Escolha a cidade' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _veiculo,
            decoration: const InputDecoration(labelText: 'Veículo', hintText: 'Ex.: HB20 2022, câmbio manual'),
            validator: limiteDeTexto(120),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _bio,
            decoration: const InputDecoration(labelText: 'Apresentação'),
            maxLines: 4,
            maxLength: 1000,
            validator: limiteDeTexto(1000),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: _ponto,
            decoration: const InputDecoration(labelText: 'Ponto de encontro'),
            validator: limiteDeTexto(300),
          ),
          const Secao('Busca do aluno'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Busco o aluno no endereço dele'),
            value: _ofereceBusca,
            onChanged: (v) => setState(() => _ofereceBusca = v),
          ),
          if (_ofereceBusca)
            TextFormField(
              controller: _taxa,
              decoration: const InputDecoration(labelText: 'Taxa de busca (R\$)', hintText: '25,00'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: validarTaxa,
            ),
          const Secao('Agenda'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Aceitando novos agendamentos'),
            subtitle: const Text('Desligue para pausar sem perder a aprovação'),
            value: _ativo,
            onChanged: (v) => setState(() => _ativo = v),
          ),
          const SizedBox(height: 16),
          BotaoAcao(texto: 'Salvar', ocupado: _ocupado, aoPressionar: _salvar),
        ],
      ),
    );
  }
}
