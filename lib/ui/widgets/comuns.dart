import 'package:flutter/material.dart';

import '../../core/erros.dart';

String mensagemDe(Object erro) =>
    erro is ErroApp ? erro.mensagem : 'Algo deu errado. Tente novamente.';

void mostrarMensagem(BuildContext context, String texto, {bool erro = false}) {
  final cores = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(texto),
      backgroundColor: erro ? cores.errorContainer : null,
      behavior: SnackBarBehavior.floating,
    ));
}

void mostrarErro(BuildContext context, Object erro) =>
    mostrarMensagem(context, mensagemDe(erro), erro: true);

class Carregando extends StatelessWidget {
  const Carregando({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

/// Falha ao carregar dados, com botão para tentar de novo.
class FalhaAoCarregar extends StatelessWidget {
  const FalhaAoCarregar({super.key, required this.erro, required this.tentar});

  final Object erro;
  final VoidCallback tentar;

  @override
  Widget build(BuildContext context) {
    final semRede = erro is ErroApp && (erro as ErroApp).tipo == TipoErro.conexao;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              semRede ? Icons.wifi_off : Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(mensagemDe(erro), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: tentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar de novo'),
            ),
          ],
        ),
      ),
    );
  }
}

class Vazio extends StatelessWidget {
  const Vazio({super.key, required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final cor = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 48, color: cor),
            const SizedBox(height: 12),
            Text(texto, textAlign: TextAlign.center, style: TextStyle(color: cor)),
          ],
        ),
      ),
    );
  }
}

/// Carrega dados de um `Future` e mostra carregando / erro com nova tentativa /
/// conteúdo. Puxar para baixo recarrega.
class Carregador<T> extends StatefulWidget {
  const Carregador({super.key, required this.carregar, required this.construir});

  final Future<T> Function() carregar;
  final Widget Function(BuildContext context, T dados, Future<void> Function() recarregar)
      construir;

  @override
  State<Carregador<T>> createState() => CarregadorState<T>();
}

class CarregadorState<T> extends State<Carregador<T>> {
  late Future<T> _futuro = widget.carregar();

  Future<void> recarregar() async {
    final futuro = widget.carregar();
    setState(() => _futuro = futuro);
    try {
      await futuro;
    } catch (_) {
      // O erro é exibido pelo FutureBuilder.
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Carregando();
          }
          if (snap.hasError) {
            return FalhaAoCarregar(erro: snap.error!, tentar: recarregar);
          }
          return RefreshIndicator(
            onRefresh: recarregar,
            child: widget.construir(context, snap.data as T, recarregar),
          );
        },
      );
}

/// Botão principal que mostra progresso enquanto a ação roda.
class BotaoAcao extends StatelessWidget {
  const BotaoAcao({
    super.key,
    required this.texto,
    required this.aoPressionar,
    this.ocupado = false,
  });

  final String texto;
  final VoidCallback? aoPressionar;
  final bool ocupado;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton(
          onPressed: ocupado ? null : aoPressionar,
          child: ocupado
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(texto),
        ),
      );
}

class Secao extends StatelessWidget {
  const Secao(this.titulo, {super.key});

  final String titulo;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
        child: Text(
          titulo.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 1,
              ),
        ),
      );
}

Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  String confirmarTexto = 'Confirmar',
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmarTexto),
          ),
        ],
      ),
    ) ??
    false;
