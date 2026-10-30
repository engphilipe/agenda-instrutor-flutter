import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/validadores.dart';
import '../../../state/sessao.dart';
import '../../widgets/comuns.dart';

class CadastroTela extends StatefulWidget {
  const CadastroTela({super.key});

  @override
  State<CadastroTela> createState() => _CadastroTelaState();
}

class _CadastroTelaState extends State<CadastroTela> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _confirmacao = TextEditingController();
  bool _instrutor = false;
  bool _aceitouTermos = false;
  bool _tentouEnviar = false;
  bool _ocupado = false;

  @override
  void dispose() {
    for (final c in [_nome, _email, _senha, _confirmacao]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cadastrar() async {
    setState(() => _tentouEnviar = true);
    if (!_form.currentState!.validate() || !_aceitouTermos) return;
    setState(() => _ocupado = true);
    try {
      await context.read<Sessao>().cadastrar(
            nome: _nome.text,
            email: _email.text,
            senha: _senha.text,
            instrutor: _instrutor,
          );
      // Logado: volta para a raiz, que agora mostra a área do usuário.
      if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Você é:', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text('Aluno'),
                      icon: Icon(Icons.school_outlined),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('Instrutor'),
                      icon: Icon(Icons.badge_outlined),
                    ),
                  ],
                  selected: {_instrutor},
                  onSelectionChanged: (s) => setState(() => _instrutor = s.first),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nome,
                  decoration: const InputDecoration(labelText: 'Nome completo'),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: validarNome,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: validarEmail,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _senha,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    helperText: 'Mínimo de 8 caracteres, com letras e números',
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  validator: validarSenha,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmacao,
                  decoration: const InputDecoration(labelText: 'Confirme a senha'),
                  obscureText: true,
                  validator: (v) =>
                      v != _senha.text ? 'As senhas não conferem' : null,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: _aceitouTermos,
                  onChanged: (v) => setState(() => _aceitouTermos = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Li e aceito os Termos de Uso e a Política de Privacidade'),
                  subtitle: _tentouEnviar && !_aceitouTermos
                      ? Text(
                          'É preciso aceitar os termos para continuar',
                          style: TextStyle(color: cores.error),
                        )
                      : null,
                ),
                if (_instrutor)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Contas de instrutor aparecem na busca dos alunos depois de '
                      'aprovadas. Enquanto isso, você já pode usar sua agenda.',
                      style: TextStyle(color: cores.onSurfaceVariant),
                    ),
                  ),
                const SizedBox(height: 8),
                BotaoAcao(
                  texto: 'Criar conta',
                  ocupado: _ocupado,
                  aoPressionar: _cadastrar,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
