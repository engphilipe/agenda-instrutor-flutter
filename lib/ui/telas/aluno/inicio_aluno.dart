import 'package:flutter/material.dart';

import '../perfil/perfil_tela.dart';
import 'buscar_tela.dart';
import 'minhas_aulas_tela.dart';

/// Área do aluno: buscar instrutor, minhas aulas e perfil.
class InicioAluno extends StatefulWidget {
  const InicioAluno({super.key});

  @override
  State<InicioAluno> createState() => _InicioAlunoState();
}

class _InicioAlunoState extends State<InicioAluno> {
  int _aba = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        // Cada troca de aba recria a tela, que busca os dados de novo no banco.
        body: switch (_aba) {
          0 => const BuscarTela(),
          1 => const MinhasAulasTela(),
          _ => const PerfilTela(),
        },
        bottomNavigationBar: NavigationBar(
          selectedIndex: _aba,
          onDestinationSelected: (i) => setState(() => _aba = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.search), label: 'Buscar'),
            NavigationDestination(
              icon: Icon(Icons.event_note_outlined),
              selectedIcon: Icon(Icons.event_note),
              label: 'Minhas aulas',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      );
}
