import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/validadores.dart';
import '../../../data/modelos.dart';
import '../../../data/perfil_repositorio.dart';
import '../../../state/sessao.dart';
import '../../widgets/comuns.dart';

/// Endereço do aluno (privado: o instrutor só vê a cópia na aula com busca).
class EnderecoTela extends StatelessWidget {
  const EnderecoTela({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<PerfilRepositorio>();
    final id = context.read<Sessao>().usuarioId;
    return Scaffold(
      appBar: AppBar(title: const Text('Meu endereço')),
      body: Carregador<(Endereco?, List<Cidade>)>(
        carregar: () async => (await repo.endereco(id), await repo.cidadesEmCache()),
        construir: (context, dados, _) =>
            _FormEndereco(endereco: dados.$1, cidades: dados.$2),
      ),
    );
  }
}

class _FormEndereco extends StatefulWidget {
  const _FormEndereco({required this.endereco, required this.cidades});

  final Endereco? endereco;
  final List<Cidade> cidades;

  @override
  State<_FormEndereco> createState() => _FormEnderecoState();
}

class _FormEnderecoState extends State<_FormEndereco> {
  final _form = GlobalKey<FormState>();
  late final _cep = TextEditingController(text: widget.endereco?.cep);
  late final _logradouro = TextEditingController(text: widget.endereco?.logradouro);
  late final _numero = TextEditingController(text: widget.endereco?.numero);
  late final _complemento = TextEditingController(text: widget.endereco?.complemento);
  late final _bairro = TextEditingController(text: widget.endereco?.bairro);
  late int? _cidadeId = widget.endereco?.cidadeId;
  bool _ocupado = false;

  @override
  void dispose() {
    for (final c in [_cep, _logradouro, _numero, _complemento, _bairro]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _ocupado = true);
    try {
      await context.read<PerfilRepositorio>().salvarEndereco(
            context.read<Sessao>().usuarioId,
            Endereco(
              cep: somenteDigitos(_cep.text),
              logradouro: _logradouro.text.trim(),
              numero: _numero.text.trim(),
              complemento: _complemento.text.trim().isEmpty ? null : _complemento.text.trim(),
              bairro: _bairro.text.trim(),
              cidadeId: _cidadeId!,
            ),
          );
      if (!mounted) return;
      mostrarMensagem(context, 'Endereço salvo.');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _cep,
              decoration: const InputDecoration(labelText: 'CEP', hintText: '00000-000'),
              keyboardType: TextInputType.number,
              validator: validarCep,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _logradouro,
              decoration: const InputDecoration(labelText: 'Rua / Avenida'),
              validator: (v) => (v?.trim().length ?? 0) < 2 ? 'Informe a rua' : limiteDeTexto(200)(v),
            ),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: TextFormField(
                  controller: _numero,
                  decoration: const InputDecoration(labelText: 'Número'),
                  validator: limiteDeTexto(20, obrigatorio: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _complemento,
                  decoration: const InputDecoration(labelText: 'Complemento'),
                  validator: limiteDeTexto(100),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bairro,
              decoration: const InputDecoration(labelText: 'Bairro'),
              validator: (v) => (v?.trim().length ?? 0) < 2 ? 'Informe o bairro' : limiteDeTexto(100)(v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _cidadeId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Cidade'),
              items: [
                for (final c in widget.cidades)
                  DropdownMenuItem(value: c.id, child: Text(c.toString())),
              ],
              onChanged: (v) => _cidadeId = v,
              validator: (v) => v == null ? 'Escolha a cidade' : null,
            ),
            const SizedBox(height: 20),
            BotaoAcao(texto: 'Salvar endereço', ocupado: _ocupado, aoPressionar: _salvar),
          ],
        ),
      );
}
