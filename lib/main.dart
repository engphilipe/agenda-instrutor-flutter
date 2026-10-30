import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api.dart';
import 'data/agenda_repositorio.dart';
import 'data/auth_repositorio.dart';
import 'data/aulas_repositorio.dart';
import 'data/busca_repositorio.dart';
import 'data/perfil_repositorio.dart';
import 'state/sessao.dart';
import 'ui/tema.dart';
import 'ui/telas/aluno/inicio_aluno.dart';
import 'ui/telas/auth/entrar.dart';
import 'ui/telas/instrutor/inicio_instrutor.dart';
import 'ui/widgets/comuns.dart';

void main() {
  final api = Api();
  final perfis = PerfilRepositorio(api);
  final sessao = Sessao(api, AuthRepositorio(api), perfis)..restaurar();

  runApp(MultiProvider(
    providers: [
      Provider.value(value: perfis),
      Provider(create: (_) => BuscaRepositorio(api)),
      Provider(create: (_) => AulasRepositorio(api)),
      Provider(create: (_) => AgendaRepositorio(api)),
      ChangeNotifierProvider.value(value: sessao),
    ],
    child: const AgendaInstrutorApp(),
  ));
}

class AgendaInstrutorApp extends StatelessWidget {
  const AgendaInstrutorApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Agenda Instrutor',
        debugShowCheckedModeBanner: false,
        theme: criarTema(),
        // No navegador, o conteúdo fica centralizado com largura de celular/tablet.
        builder: (context, child) => ColoredBox(
          color: Cores.fundo,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: child,
            ),
          ),
        ),
        home: const Raiz(),
      );
}

/// Escolhe a tela inicial conforme a sessão: login, área do aluno ou do instrutor.
class Raiz extends StatelessWidget {
  const Raiz({super.key});

  @override
  Widget build(BuildContext context) {
    final sessao = context.watch<Sessao>();
    return switch (sessao.estado) {
      EstadoSessao.carregando => const Scaffold(body: Carregando()),
      EstadoSessao.deslogado => const EntrarTela(),
      EstadoSessao.logado => sessao.perfil!.ehInstrutor
          ? const InicioInstrutor()
          : const InicioAluno(),
    };
  }
}
