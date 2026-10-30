import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/validadores.dart';
import '../../../state/sessao.dart';
import '../../tema.dart';
import '../../widgets/comuns.dart';
import 'cadastro.dart';

class EntrarTela extends StatefulWidget {
  const EntrarTela({super.key});

  @override
  State<EntrarTela> createState() => _EntrarTelaState();
}

class _EntrarTelaState extends State<EntrarTela> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _ocupado = false;
  bool _verSenha = false;

  @override
  void initState() {
    super.initState();
    final erro = context.read<Sessao>().erroAoRestaurar;
    if (erro != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => mounted ? mostrarMensagem(context, erro, erro: true) : null,
      );
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _ocupado = true);
    try {
      await context.read<Sessao>().entrar(_email.text, _senha.text);
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.directions_car, size: 56, color: Cores.primaria),
                    const SizedBox(height: 12),
                    Text(
                      'Agenda Instrutor',
                      textAlign: TextAlign.center,
                      style: texto.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Aulas de direção com instrutores autônomos',
                      textAlign: TextAlign.center,
                      style: texto.bodyMedium?.copyWith(color: Cores.textoSuave),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      validator: validarEmail,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _senha,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _verSenha ? 'Ocultar senha' : 'Mostrar senha',
                          icon: Icon(_verSenha ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _verSenha = !_verSenha),
                        ),
                      ),
                      obscureText: !_verSenha,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _entrar(),
                      validator: (v) => obrigatorio(v, 'Senha'),
                    ),
                    const SizedBox(height: 24),
                    BotaoAcao(texto: 'Entrar', ocupado: _ocupado, aoPressionar: _entrar),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _ocupado
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CadastroTela()),
                              ),
                      child: const Text('Não tem conta? Cadastre-se'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
