import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/formatacao.dart';
import '../../../data/busca_repositorio.dart';
import '../../../data/modelos.dart';
import '../../../data/perfil_repositorio.dart';
import '../../../state/sessao.dart';
import '../../tema.dart';
import '../../widgets/comuns.dart';
import 'instrutor_tela.dart';

/// Busca de instrutores: categoria (moto/carro), cidade e nome.
class BuscarTela extends StatefulWidget {
  const BuscarTela({super.key});

  @override
  State<BuscarTela> createState() => _BuscarTelaState();
}

class _BuscarTelaState extends State<BuscarTela> {
  final _nome = TextEditingController();
  String _categoria = 'B';
  int? _cidadeId;
  late Future<List<Cidade>> _cidades;
  late Future<List<Instrutor>> _resultado;

  @override
  void initState() {
    super.initState();
    _cidadeId = context.read<Sessao>().perfil?.cidadeId;
    _cidades = context.read<PerfilRepositorio>().cidadesEmCache();
    _buscar();
  }

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  void _buscar() {
    setState(() {
      _resultado = context.read<BuscaRepositorio>().instrutores(
            categoria: _categoria,
            cidadeId: _cidadeId,
            nome: _nome.text,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final nome = context.watch<Sessao>().perfil?.nome.split(' ').first ?? '';
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'Olá, '),
                TextSpan(text: nome, style: const TextStyle(color: Cores.primaria)),
              ]),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'B', label: Text('Carro (B)'), icon: Icon(Icons.directions_car)),
                    ButtonSegment(value: 'A', label: Text('Moto (A)'), icon: Icon(Icons.two_wheeler)),
                  ],
                  selected: {_categoria},
                  onSelectionChanged: (s) {
                    _categoria = s.first;
                    _buscar();
                  },
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<Cidade>>(
                  future: _cidades,
                  builder: (context, snap) => DropdownButtonFormField<int?>(
                    initialValue: _cidadeId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Cidade',
                      prefixIcon: const Icon(Icons.location_city),
                      errorText: snap.hasError ? mensagemDe(snap.error!) : null,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todas as cidades')),
                      for (final c in snap.data ?? const <Cidade>[])
                        DropdownMenuItem(value: c.id, child: Text(c.toString())),
                    ],
                    onChanged: (v) {
                      _cidadeId = v;
                      _buscar();
                    },
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nome,
                  decoration: InputDecoration(
                    labelText: 'Nome do instrutor',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      tooltip: 'Buscar',
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: _buscar,
                    ),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _buscar(),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Instrutor>>(
              future: _resultado,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) return const Carregando();
                if (snap.hasError) return FalhaAoCarregar(erro: snap.error!, tentar: _buscar);
                final lista = snap.data!;
                if (lista.isEmpty) {
                  return const Vazio(
                    icone: Icons.person_search,
                    texto: 'Nenhum instrutor encontrado com esses filtros.\n'
                        'Tente outra cidade ou categoria.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: lista.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _CartaoInstrutor(lista[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoInstrutor extends StatelessWidget {
  const _CartaoInstrutor(this.instrutor);

  final Instrutor instrutor;

  @override
  Widget build(BuildContext context) {
    final i = instrutor;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Cores.campo,
          child: Text(i.nome.isEmpty ? '?' : i.nome[0].toUpperCase()),
        ),
        title: Text(i.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text([
          if (i.cidade != null) i.cidade!,
          i.categorias.map((c) => nomesCategoria[c] ?? c).join(' · '),
          if (i.veiculo != null) i.veiculo!,
        ].join('\n')),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, size: 18, color: Cores.nota),
            const SizedBox(width: 2),
            Text(i.totalAvaliacoes == 0 ? 'Novo' : i.notaMedia.toStringAsFixed(1)),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => InstrutorTela(instrutor: i)),
        ),
      ),
    );
  }
}
