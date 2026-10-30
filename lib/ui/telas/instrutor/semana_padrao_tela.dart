import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/formatacao.dart';
import '../../../core/grade.dart';
import '../../../core/tempo.dart';
import '../../../data/agenda_repositorio.dart';
import '../../../state/sessao.dart';
import '../../tema.dart';
import '../../widgets/comuns.dart';

/// Semana padrão: quais horários ficam abertos para agendamento em cada dia da semana.
class SemanaPadraoTela extends StatelessWidget {
  const SemanaPadraoTela({super.key});

  @override
  Widget build(BuildContext context) {
    final id = context.read<Sessao>().usuarioId;
    return Scaffold(
      appBar: AppBar(title: const Text('Horários de atendimento')),
      body: Carregador<Map<int, Set<int>>>(
        carregar: () async => semanaDasRegras(await context.read<AgendaRepositorio>().regras(id)),
        construir: (context, semana, _) => _EditorSemana(semana),
      ),
    );
  }
}

class _EditorSemana extends StatefulWidget {
  const _EditorSemana(this.salva);

  final Map<int, Set<int>> salva;

  @override
  State<_EditorSemana> createState() => _EditorSemanaState();
}

class _EditorSemanaState extends State<_EditorSemana> {
  late final _semana = {for (final e in widget.salva.entries) e.key: {...e.value}};
  late final _salva = {for (final e in widget.salva.entries) e.key: {...e.value}};
  int _dia = 1;
  bool _ocupado = false;

  bool get _alterada => List.generate(7, (d) => d).any((d) =>
      _semana[d]!.length != _salva[d]!.length || !_semana[d]!.containsAll(_salva[d]!));

  Future<void> _salvar() async {
    setState(() => _ocupado = true);
    try {
      await context.read<AgendaRepositorio>().salvarSemana(_semana);
      if (!mounted) return;
      setState(() {
        for (var d = 0; d < 7; d++) {
          _salva[d] = {..._semana[d]!};
        }
      });
      mostrarMensagem(context, 'Horários salvos.');
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  void _alternar(int hora) => setState(() {
        final horas = _semana[_dia]!;
        horas.contains(hora) ? horas.remove(hora) : horas.add(hora);
      });

  @override
  Widget build(BuildContext context) {
    final horas = _semana[_dia]!;
    return Column(children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            Text(
              'Escolha os horários em que os alunos podem agendar. '
              'Vale para todas as semanas.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final d in [1, 2, 3, 4, 5, 6, 0])
                ChoiceChip(
                  label: Text('${diasDaSemana[d].substring(0, 3)} (${_semana[d]!.length})'),
                  selected: d == _dia,
                  onSelected: (_) => setState(() => _dia = d),
                ),
            ]),
            const Secao('Horários'),
            Row(children: [
              TextButton(
                onPressed: () => setState(() => horas.addAll(horasDaGrade)),
                child: const Text('Abrir todos'),
              ),
              TextButton(
                onPressed: () => setState(horas.clear),
                child: const Text('Fechar todos'),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() {
                  for (final d in [1, 2, 3, 4, 5]) {
                    _semana[d] = {...horas};
                  }
                }),
                child: const Text('Copiar p/ seg–sex'),
              ),
            ]),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final h in horasDaGrade)
                FilterChip(
                  label: Text(horaTexto(h)),
                  selected: horas.contains(h),
                  selectedColor: Cores.primaria.withValues(alpha: 0.25),
                  onSelected: (_) => _alternar(h),
                ),
            ]),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: BotaoAcao(
          texto: _alterada ? 'Salvar alterações' : 'Tudo salvo',
          ocupado: _ocupado,
          aoPressionar: _alterada ? _salvar : null,
        ),
      ),
    ]);
  }
}
