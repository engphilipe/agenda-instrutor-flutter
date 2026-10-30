# Agenda Instrutor (Flutter)

Aplicativo multiplataforma (**Android** e **Web**) feito em **Flutter/Dart** para agendar aulas de direção entre
**instrutores autônomos** e **alunos**. O instrutor define os horários em que atende; o aluno encontra o
instrutor, vê os horários livres e agenda.

Todos os dados ficam em um banco **PostgreSQL real (Supabase)**, acessado por **requisições HTTP** à API REST
(PostgREST) e à API de autenticação. Nada é simulado nem fica só na memória: fechar e abrir o app mantém os dados e
a sessão.

## Funcionalidades

| Requisito         | Onde está no app                                                                                                                              |
| ----------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| **Consulta**      | Busca de instrutores por categoria (moto/carro), cidade e nome; horários livres do instrutor; minhas aulas; agenda do dia do instrutor.     |
| **Cadastro**      | Criar conta (aluno ou instrutor); agendar aula; instrutor lança aula manual; endereço do aluno; perfil pessoal e profissional; semana padrão. |
| **Alteração**     | Cancelar aula; registrar aula concluída / falta; editar perfil, endereço e horários de atendimento.                                         |
| **Persistência**  | Dados no banco (Supabase/PostgreSQL). Sessão salva no aparelho (`shared_preferences` → `localStorage` no navegador).                         |
| **Atualização**   | Telas recarregam do banco após cada alteração; puxar para baixo recarrega; trocar de aba busca os dados de novo.                             |
| **Erros**         | Campos inválidos (validação em todos os formulários), sem conexão, tempo esgotado, serviço fora do ar e regras de negócio do banco.          |

### Aluno

- **Buscar**: escolhe carro (B) ou moto (A), cidade e nome → lista de instrutores aprovados.
- **Instrutor**: dados, avaliação e horários livres das próximas 2 semanas → toca no horário → confirma (ponto de
  encontro ou busca em casa com taxa) → aula criada já confirmada.
- **Minhas aulas**: próximas e histórico; cancelamento permitido até **2 h** antes.
- **Perfil**: nome, telefone, cidade e endereço.

### Instrutor

- **Agenda**: os 19 horários do dia (04:00 a 22:00, aulas de 50 min) com aulas, horários abertos e fechados. Toca
  num horário vazio → lança aula; toca numa aula → cancela ou registra concluída/falta.
- **Horários**: semana padrão (quais horas ficam abertas em cada dia da semana).
- **Perfil profissional**: categorias, cidade, veículo, apresentação, ponto de encontro, taxa de busca e pausa da
  agenda.

> Um instrutor recém-cadastrado fica **em análise** e só aparece na busca dos alunos depois de aprovado por um
> administrador no banco. A agenda dele já funciona antes disso.

## Regras de negócio (garantidas pelo banco)

- Aulas de 50 min começando na hora cheia, das 04:00 às 22:00 (horário de Brasília).
- O aluno só agenda horário aberto pelo instrutor e livre; dois alunos não pegam o mesmo horário, nem o aluno fica
  em duas aulas ao mesmo tempo.
- O aluno cancela até 2 h antes; o instrutor cancela a qualquer momento antes do início.
- Cada usuário só lê e altera os próprios dados (Row Level Security). Gravações de aula passam por funções do
  banco (`agendar_aula`, `cancelar_aula`, `lancar_aula`, `registrar_desfecho_aula`, `definir_regras_semanais`).

Quando o banco recusa algo, ele devolve um código (ex.: `HORARIO_INDISPONIVEL`) que o app converte em mensagem em
português.

## Arquitetura

```
lib/
  config.dart              URL e chave pública do Supabase
  main.dart                injeção de dependências (provider) e escolha da tela inicial
  core/                    sem Flutter: regras e utilitários puros
    api.dart               cliente HTTP (cabeçalhos, timeout, renovação do token, erros)
    erros.dart             ErroApp + conversão das respostas de erro em mensagens
    grade.dart             cálculo de horários livres e semana padrão
    tempo.dart             fuso de São Paulo (UTC-3)
    validadores.dart       validação dos formulários
    formatacao.dart        datas, moeda e telefone em pt-BR
  data/                    repositórios: cada um conversa com uma parte da API
    modelos.dart           classes de dados (fromJson/toJson)
    auth_repositorio.dart  /auth/v1 (cadastro, login, renovação, logout)
    perfil_repositorio.dart, busca_repositorio.dart, aulas_repositorio.dart, agenda_repositorio.dart
  state/sessao.dart        ChangeNotifier da sessão (login, persistência dos tokens)
  ui/                      telas e componentes (tema, carregamento, erro com "tentar de novo")
test/                      testes unitários de regras, validação, erros e do cliente HTTP (com MockClient)
```

Fluxo: **Tela → Repositório → Api (HTTP) → Supabase**. As telas nunca montam requisições; os repositórios nunca
desenham nada.

## Como rodar

Pré-requisitos: Flutter 3.41+ (Dart 3.11+). Para Android: Android Studio com SDK e um emulador ou aparelho.

```bash
flutter pub get
```

**Navegador**

```bash
flutter run -d chrome
```

**Android** (emulador aberto ou aparelho com depuração USB)

```bash
flutter run -d android
```

Gerar APK:

```bash
flutter build apk --release
```

> O Gradle do projeto (8.14) precisa de Java 17 a 24. Se o seu Java padrão for mais novo, aponte para o JDK do
> Android Studio: `flutter config --jdk-dir="C:\Program Files\Android\Android Studio\jbr"`.

**Testes e análise**

```bash
flutter test
flutter analyze
```

### Outro backend Supabase

A URL e a chave pública podem ser trocadas no build, sem alterar o código:

```bash
flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co --dart-define=SUPABASE_KEY=sb_publishable_xxx
```

A chave *publishable* é pública por natureza (vai dentro do app); a segurança dos dados é feita pelas policies RLS
do banco.
