import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/erros.dart';
import '../../../core/formatacao.dart';
import '../../../core/grade.dart';
import '../../../core/tempo.dart';
import '../../../core/validadores.dart';
import '../../../data/busca_repositorio.dart';
import '../../../data/modelos.dart';
import '../../tema.dart';
import '../../widgets/comuns.dart';

/// Perfil do instrutor com os horários livres das próximas 2 semanas.
class InstrutorTela extends StatefulWidget {
  const InstrutorTela({super.key, required this.instrutor});

  final Instrutor instrutor;

  @override
  State<InstrutorTela> createState() => _InstrutorTelaState();
}

class _InstrutorTelaState extends State<InstrutorTela> {
  final _carregador = GlobalKey<CarregadorState<Map<DateTime, List<Horario>>>>();
  DateTime? _diaEscolhido;

  Future<void> _agendar(Horario horario) async {
    final agendou = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ConfirmarAgendamento(instrutor: widget.instrutor, horario: horario),
    );
    if (agendou == true && mounted) {
      mostrarMensagem(context, 'Aula agendada! Veja em "Minhas aulas".');
    }
    // Agendou ou o horário foi ocupado por outra pessoa: atualiza a grade.
    if (agendou != null) await _carregador.currentState?.recarregar();
  }

  @override
  Widget build(BuildContext context) {
    final i = widget.instrutor;
    final suave = TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return Scaffold(
      appBar: AppBar(title: Text(i.nome)),
      body: Carregador<Map<DateTime, List<Horario>>>(
        key: _carregador,
        carregar: () => context.read<BuscaRepositorio>().horariosLivres(i.id),
        construir: (context, porDia, _) {
          final dias = porDia.keys.toList();
          final dia = dias.contains(_diaEscolhido) ? _diaEscolhido! : dias.firstOrNull;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        for (final c in i.categorias) Chip(label: Text(nomesCategoria[c] ?? c)),
                        Chip(
                          avatar: const Icon(Icons.star, size: 16, color: Cores.nota),
                          label: Text(i.totalAvaliacoes == 0
                              ? 'Sem avaliações'
                              : '${i.notaMedia.toStringAsFixed(1)} (${i.totalAvaliacoes})'),
                        ),
                      ]),
                      if (i.bio != null) ...[const SizedBox(height: 12), Text(i.bio!)],
                      const SizedBox(height: 12),
                      _Linha(Icons.location_city, i.cidade ?? 'Cidade não informada'),
                      if (i.veiculo != null) _Linha(Icons.directions_car, i.veiculo!),
                      if (i.regiaoAtuacao != null) _Linha(Icons.map_outlined, i.regiaoAtuacao!),
                      if (i.pontoEncontro != null)
                        _Linha(Icons.place_outlined, 'Ponto de encontro: ${i.pontoEncontro}'),
                      if (i.ofereceBusca && i.taxaBuscaCentavos != null)
                        _Linha(Icons.home_outlined,
                            'Busca no seu endereço: + ${formatarMoeda(i.taxaBuscaCentavos!)}'),
                    ],
                  ),
                ),
              ),
              const Secao('Horários disponíveis'),
              if (dia == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Vazio(
                    icone: Icons.event_busy,
                    texto: 'Nenhum horário livre nas próximas 2 semanas.',
                  ),
                )
              else ...[
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: dias.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, n) => ChoiceChip(
                      label: Text(formatarData(dias[n])),
                      selected: dias[n] == dia,
                      onSelected: (_) => setState(() => _diaEscolhido = dias[n]),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final h in porDia[dia]!)
                      ActionChip(
                        avatar: const Icon(Icons.schedule, size: 16),
                        label: Text(horaTexto(h.hora)),
                        onPressed: () => _agendar(h),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Aulas de 50 minutos. Toque em um horário para agendar.', style: suave),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha(this.icone, this.texto);

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, size: 18, color: Cores.textoSuave),
            const SizedBox(width: 8),
            Expanded(child: Text(texto)),
          ],
        ),
      );
}

/// Confirmação: local da aula e observação para o instrutor.
/// Fecha com `true` se agendou e `false` se o horário deixou de estar livre.
class _ConfirmarAgendamento extends StatefulWidget {
  const _ConfirmarAgendamento({required this.instrutor, required this.horario});

  final Instrutor instrutor;
  final Horario horario;

  @override
  State<_ConfirmarAgendamento> createState() => _ConfirmarAgendamentoState();
}

class _ConfirmarAgendamentoState extends State<_ConfirmarAgendamento> {
  final _form = GlobalKey<FormState>();
  final _observacao = TextEditingController();
  bool _busca = false;
  bool _ocupado = false;

  @override
  void dispose() {
    _observacao.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _ocupado = true);
    try {
      await context.read<BuscaRepositorio>().agendar(
            instrutorId: widget.instrutor.id,
            inicio: widget.horario.inicio,
            busca: _busca,
            observacao: _observacao.text,
          );
      if (mounted) Navigator.pop(context, true);
    } on ErroApp catch (e) {
      if (!mounted) return;
      mostrarErro(context, e);
      if (e.codigo == 'HORARIO_INDISPONIVEL') Navigator.pop(context, false);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i = widget.instrutor;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Confirmar aula', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('${i.nome} · ${formatarAula(widget.horario.inicio)}'),
            const SizedBox(height: 16),
            if (i.ofereceBusca) ...[
              RadioGroup<bool>(
                groupValue: _busca,
                onChanged: (v) => setState(() => _busca = v ?? false),
                child: Column(children: [
                  RadioListTile(
                    value: false,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Vou ao ponto de encontro'),
                    subtitle: i.pontoEncontro == null ? null : Text(i.pontoEncontro!),
                  ),
                  RadioListTile(
                    value: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Quero ser buscado no meu endereço'),
                    subtitle: Text('Taxa adicional de ${formatarMoeda(i.taxaBuscaCentavos ?? 0)}'
                        ' (paga direto ao instrutor)'),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
            ],
            TextFormField(
              controller: _observacao,
              decoration: const InputDecoration(
                labelText: 'Observação para o instrutor (opcional)',
              ),
              maxLines: 3,
              maxLength: 500,
              validator: limiteDeTexto(500),
            ),
            const SizedBox(height: 8),
            BotaoAcao(texto: 'Agendar', ocupado: _ocupado, aoPressionar: _confirmar),
          ],
        ),
      ),
    );
  }
}
