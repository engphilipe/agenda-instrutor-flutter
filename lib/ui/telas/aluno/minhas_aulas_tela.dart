import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/formatacao.dart';
import '../../../core/tempo.dart';
import '../../../data/aulas_repositorio.dart';
import '../../../data/modelos.dart';
import '../../../state/sessao.dart';
import '../../tema.dart';
import '../../widgets/comuns.dart';

/// Aulas do aluno: próximas (com cancelamento até 2 h antes) e histórico.
class MinhasAulasTela extends StatelessWidget {
  const MinhasAulasTela({super.key});

  @override
  Widget build(BuildContext context) {
    final alunoId = context.read<Sessao>().usuarioId;
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas aulas')),
      body: Carregador<List<Aula>>(
        carregar: () => context.read<AulasRepositorio>().doAluno(alunoId),
        construir: (context, aulas, recarregar) {
          final agora = DateTime.now();
          final proximas = aulas.where((a) => a.ativa && a.fim.isAfter(agora)).toList()
            ..sort((a, b) => a.inicio.compareTo(b.inicio));
          final historico = aulas.where((a) => !proximas.contains(a)).toList();
          if (aulas.isEmpty) {
            return ListView(children: const [
              SizedBox(height: 120),
              Vazio(
                icone: Icons.event_available,
                texto: 'Você ainda não tem aulas.\nBusque um instrutor para agendar.',
              ),
            ]);
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              const Secao('Próximas'),
              if (proximas.isEmpty) const Text('Nenhuma aula marcada.'),
              for (final a in proximas) _CartaoAula(a, aoCancelar: recarregar),
              if (historico.isNotEmpty) ...[
                const Secao('Histórico'),
                for (final a in historico) _CartaoAula(a),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CartaoAula extends StatefulWidget {
  const _CartaoAula(this.aula, {this.aoCancelar});

  final Aula aula;
  final Future<void> Function()? aoCancelar;

  @override
  State<_CartaoAula> createState() => _CartaoAulaState();
}

class _CartaoAulaState extends State<_CartaoAula> {
  bool _ocupado = false;

  bool get _podeCancelar =>
      widget.aula.ativa &&
      widget.aula.inicio.difference(DateTime.now()) >= antecedenciaCancelamento;

  Future<void> _cancelar() async {
    final ok = await confirmar(
      context,
      titulo: 'Cancelar aula?',
      mensagem: formatarAula(widget.aula.inicio),
      confirmarTexto: 'Cancelar aula',
    );
    if (!ok || !mounted) return;
    setState(() => _ocupado = true);
    try {
      await context.read<AulasRepositorio>().cancelar(widget.aula.id, motivo: 'Cancelada pelo aluno');
      if (!mounted) return;
      mostrarMensagem(context, 'Aula cancelada.');
      await widget.aoCancelar?.call();
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.aula;
    final suave = TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(formatarAula(a.inicio),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                ChipStatus(a.status),
              ]),
              const SizedBox(height: 6),
              Text('Instrutor: ${a.contraparte?.nome ?? '—'}'),
              if (a.contraparte?.telefone != null)
                Text(formatarTelefone(a.contraparte!.telefone), style: suave),
              Text(
                a.localTipo == 'busca'
                    ? 'Busca no endereço (+ ${formatarMoeda(a.taxaBuscaCentavos ?? 0)})'
                    : 'Ponto de encontro',
                style: suave,
              ),
              if (a.observacaoAluno != null) Text('Obs.: ${a.observacaoAluno}', style: suave),
              if (a.motivoCancelamento != null) Text(a.motivoCancelamento!, style: suave),
              if (widget.aoCancelar != null && a.ativa) ...[
                const SizedBox(height: 8),
                if (_podeCancelar)
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: _ocupado ? null : _cancelar,
                      icon: const Icon(Icons.close),
                      label: const Text('Cancelar'),
                      style: OutlinedButton.styleFrom(foregroundColor: Cores.perigoTexto),
                    ),
                  )
                else
                  Text('Cancelamento só até 2 h antes da aula.', style: suave),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ChipStatus extends StatelessWidget {
  const ChipStatus(this.status, {super.key});

  final StatusAula status;

  @override
  Widget build(BuildContext context) {
    final cor = switch (status) {
      StatusAula.confirmada || StatusAula.pendente => Cores.primaria,
      StatusAula.concluida => Cores.sucesso,
      StatusAula.cancelada || StatusAula.faltou => Cores.perigoTexto,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(nomesStatus[status]!, style: TextStyle(color: cor, fontSize: 12)),
    );
  }
}
