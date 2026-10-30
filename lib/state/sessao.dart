import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api.dart';
import '../core/erros.dart';
import '../data/auth_repositorio.dart';
import '../data/modelos.dart';
import '../data/perfil_repositorio.dart';

enum EstadoSessao { carregando, deslogado, logado }

/// Sessão do usuário: login, cadastro e saída. Os tokens ficam salvos no
/// aparelho (SharedPreferences → localStorage no navegador), então o usuário
/// continua logado ao fechar e abrir o app.
class Sessao extends ChangeNotifier {
  Sessao(this._api, this._auth, this._perfis) {
    _api.token = () => _sessao?.accessToken;
    _api.renovarToken = _renovar;
  }

  static const _chave = 'sessao';

  final Api _api;
  final AuthRepositorio _auth;
  final PerfilRepositorio _perfis;

  SessaoAuth? _sessao;
  Perfil? _perfil;
  EstadoSessao _estado = EstadoSessao.carregando;
  String? erroAoRestaurar;

  EstadoSessao get estado => _estado;
  Perfil? get perfil => _perfil;
  String get usuarioId => _sessao!.usuarioId;
  String get email => _sessao?.email ?? '';

  /// Abre o app com a sessão salva, se houver.
  Future<void> restaurar() async {
    final prefs = await SharedPreferences.getInstance();
    final salvo = prefs.getString(_chave);
    if (salvo == null) return _mudar(EstadoSessao.deslogado);
    try {
      _sessao = SessaoAuth.deJson(jsonDecode(salvo) as Map<String, dynamic>);
      if (_sessao!.expirada && !await _renovar()) {
        return _mudar(EstadoSessao.deslogado);
      }
      _perfil = await _perfis.meuPerfil(usuarioId);
      _mudar(EstadoSessao.logado);
    } on ErroApp catch (e) {
      if (e.tipo == TipoErro.autenticacao) await _limpar();
      erroAoRestaurar = e.mensagem;
      _mudar(EstadoSessao.deslogado);
    }
  }

  Future<void> entrar(String email, String senha) async {
    await _iniciar(await _auth.entrar(email, senha));
  }

  Future<void> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required bool instrutor,
  }) async {
    await _iniciar(await _auth.cadastrar(
      nome: nome,
      email: email,
      senha: senha,
      instrutor: instrutor,
    ));
  }

  Future<void> sair() async {
    try {
      await _auth.sair();
    } on ErroApp {
      // Sem rede: a sessão local é apagada mesmo assim.
    }
    await _limpar();
    _mudar(EstadoSessao.deslogado);
  }

  /// Atualiza o perfil exibido depois de uma edição.
  void perfilAtualizado(Perfil perfil) {
    _perfil = perfil;
    notifyListeners();
  }

  Future<void> _iniciar(SessaoAuth sessao) async {
    _sessao = sessao;
    try {
      _perfil = await _perfis.meuPerfil(sessao.usuarioId);
    } on ErroApp {
      _sessao = null;
      rethrow;
    }
    await _salvar();
    _mudar(EstadoSessao.logado);
  }

  Future<bool> _renovar() async {
    final atual = _sessao;
    if (atual == null) return false;
    try {
      _sessao = await _auth.renovar(atual.refreshToken);
      await _salvar();
      return true;
    } on ErroApp catch (e) {
      if (e.tipo == TipoErro.conexao) rethrow;
      await _limpar();
      _mudar(EstadoSessao.deslogado);
      return false;
    }
  }

  Future<void> _salvar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chave, jsonEncode(_sessao!.paraJson()));
  }

  Future<void> _limpar() async {
    _sessao = null;
    _perfil = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chave);
  }

  void _mudar(EstadoSessao estado) {
    _estado = estado;
    notifyListeners();
  }
}
