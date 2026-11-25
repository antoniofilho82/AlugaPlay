# AlugaPlay — Relatório Técnico

> **Estado verificado:** 25 de novembro de 2026  
> **Escopo:** aplicação Flutter, testes de widget e recursos nativos Android de abertura.  
> **Validação:** `flutter analyze && flutter test --no-pub`

Este relatório descreve o estado atual do repositório. O AlugaPlay é um protótipo demonstrativo: autenticação, catálogo, estimativas e solicitações são locais. Não há servidor, estoque em tempo real, reserva comercial, cobrança, consulta de KYC ou pagamento externo.

## 1. Estrutura e navegação

```text
lib/
├── app/app.dart
├── main.dart
├── routes/app_routes.dart
├── theme/app_theme.dart
├── components/
├── data/mock_products.dart
├── models/
├── services/
└── screens/
    ├── splash/
    ├── login/
    ├── home/
    ├── product_details/
    └── rental/
test/widget_test.dart
```

`AlugaPlayApp` centraliza tema claro/escuro e rotas nomeadas. `HomeScreen` mantém as abas Início, Categorias, Meus Aluguéis e Perfil em um `IndexedStack`, preservando o estado enquanto alterna entre elas. Um histórico interno permite que o botão Voltar percorra abas visitadas antes de limpar filtros ou sair da Home.

`ProductDetailsScreen` recebe o produto como argumento da rota. Quando o argumento não é um `Product`, o catálogo local fornece o primeiro item como fallback. O mesmo produto é repassado para `RentalScreen`.

## 2. Inicialização e identidade visual

`main()` usa `WidgetsFlutterBinding.ensureInitialized`, inicia `StartupService.initialize` com `LocalStorageService.init`, restauração da autenticação e restauração dos aluguéis, e chama `runApp`. A inicialização ocorre antes da navegação da Splash, mas não bloqueia diretamente a construção inicial do app.

`StartupService` compartilha a `Future` da restauração e o estado de erro. `SplashScreen` aguarda essa `Future` somente quando `isReady` ainda é falso, exige pelo menos três segundos de visibilidade e usa `mounted` e `_hasNavigated` para evitar rota dupla ou atualização após descarte. Em caso de falha, apresenta opção de tentar novamente.

A tela usa `assets/images/splash_screen.png`, fundo preto e barra de progresso ciano. Não utiliza `CustomPainter`, asset antigo `splash_bg.jpeg` ou elementos verdes. A tela não afirma disponibilidade ou autenticação de backend.

A identidade Flutter usa azul `#2563EB`, ciano `#38BDF8`, azul-noturno `#050811`, azul profundo `#1D4ED8` e amarelo `#FACC15`. `AppTheme` possui temas claro/escuro cacheados e um `ValueNotifier<ThemeMode>` para alternância em runtime; `themeAnimationDuration` é `Duration.zero`.

### Abertura nativa Android

A janela nativa usa o fundo `#050811`. `launch_background.xml` e `drawable-v21/launch_background.xml` usam apenas esse fundo. Android 12+ usa o mesmo fundo e define o ícone animado transparente no launch theme. O ícone da aplicação é configurado como adaptativo por `flutter_launcher_icons`, mas o comportamento visual nativo não deve ser considerado validado sem build ou execução em dispositivo.

## 3. Arquitetura e responsabilidades

- **Interface:** `screens/`, `components/` e `routes/` concentram telas, widgets reutilizáveis e constantes de navegação.
- **Serviços:** `StartupService` coordena a inicialização; `LocalStorageService` encapsula JSON em `SharedPreferences`; `LocalAuthService` controla contas demonstrativas, sessão, perfil e preferências.
- **Modelos/dados:** `Product`, `Rental` e `UserProfile` representam dados locais; `mockProducts` fornece o catálogo demonstrativo.
- **Persistência:** a aplicação grava usuários, sessão, perfil, preferências e solicitações em chaves separadas do `SharedPreferences`.
- **Tema:** `AppTheme` centraliza cores, gradientes, raios e estilos globais.

## 4. Catálogo e filtros locais

O catálogo contém dados fictícios locais de consoles, jogos físicos e pacotes. Não há carregamento por rede.

Na aba Início, categoria, texto de busca, plataforma e estilo são combinados. Nenhum filtro substitui outro:

- Categoria usa `Todos`, `Consoles`, `Jogos` ou `Pacotes`.
- Plataforma deriva dos campos `platform` do catálogo.
- Estilo não é um campo do modelo; é inferido por palavras-chave em nome, descrição e especificações.
- O modal aplica plataforma e estilo juntos somente ao confirmar.
- Buscar e limpar filtros também atualiza o estado local da tela.

A combinação pode não encontrar resultados; a interface apresenta um estado vazio com ação para limpar filtros.

## 5. Contas, perfil e sessão

`LocalAuthService` mantém contas em memória durante a execução e delega persistência a `LocalStorageService`. O cadastro valida nome, telefone, formato de e-mail e senha com pelo menos seis caracteres. A tela de Login autentica somente contra a conta criada no dispositivo.

Com `Lembrar meu acesso` ativo, a sessão persiste `rememberAccess`, `rememberedEmail` e `currentUserEmail`; nunca persiste a senha. `shouldAutoLogin` exige simultaneamente a opção ativa e uma conta atual restaurada. Logout remove a sessão ativa, mas mantém contas e solicitações locais.

A senha é salva em JSON no registro da conta para viabilizar autenticação demonstrativa e não é cifrada por `SharedPreferences`. Esse mecanismo não oferece segurança adequada para produção. Recuperação de senha altera apenas o registro local e não envia mensagens externas.

O perfil persiste nome, e-mail, telefone, cidade, endereço, CPF e caminho da foto. A foto é escolhida pela galeria e seu caminho é armazenado; uma imagem inacessível usa a inicial do nome sobre degradê azul.

O CPF é opcional. Quando informado ou editado no Perfil, a validação remove pontuação, rejeita tamanho incorreto e sequências repetidas e calcula os dois dígitos verificadores pelo módulo 11. Não há consulta externa. `isKycVerified` permanece um estado demonstrativo não verificado pelo aplicativo.

## 6. Persistência local

`LocalStorageService` inicializa uma única instância de `SharedPreferences` e usa JSON nas chaves `alugaplay.users`, `session`, `profile`, `preferences` e `rentals`.

| Dados | Conteúdo |
|---|---|
| Usuários | Nome, e-mail, telefone, cidade, endereço, CPF, senha e estado KYC. |
| Sessão | Opção “lembrar”, e-mail lembrado e e-mail da conta atual. |
| Perfil | Nome, e-mail, telefone, endereço, cidade, CPF e caminho da foto. |
| Preferências | Tema, notificações, modalidade, duração padrão e plataforma favorita. |
| Solicitações | Produto, datas, duração, total estimado, observações, estado e endereço/modalidade. |

JSON ausente resulta em coleções ou mapas vazios. JSON malformado ou estrutura inesperada lança exceção em vez de substituir os dados silenciosamente. Não há criptografia, sincronização remota, migração de esquema ou recuperação automática de dados corrompidos.

`Rental.toJson()` e `Rental.fromJson()` serializam também PIN, número de série, checklist, caução, pagamento e aceite dos termos. Esses campos não são coletados pelo formulário atual e permanecem vazios ou nos valores padrão. O teste preenche-os diretamente no modelo para validar serialização.

## 7. Solicitação de aluguel

`RentalScreen` recebe o produto da rota, escolhe data inicial e final, modalidade retirada/delivery, endereço opcional de entrega e observações. Datas são normalizadas para meia-noite e períodos menores que um dia são bloqueados.

A estimativa usa a tarifa do produto multiplicada pela duração. Se o produto estiver marcado com unidade semanal, o código divide a tarifa por sete para formar uma tarifa diária; o catálogo atual utiliza apenas tarifas diárias.

Ao confirmar, cria um `Rental` com datas, duração, total estimado, observações e dados de entrega, adiciona o registro à lista em memória e salva o JSON local. A interface informa que não há cobrança real. Meus Aluguéis permite cancelar ou limpar solicitações.

## 8. Técnicas de implementação e performance

As técnicas presentes no código são:

- Widgets temáticos em `ThemeData` construídos uma vez e reutilizados.
- `IndexedStack` para preservar telas da navegação por abas.
- Filtros em listas locais com `where` e inferência de estilo por texto.
- Inicialização assíncrona compartilhada pela Splash.
- Controllers encerrados nos métodos `dispose`.
- Verificação de `mounted` antes de `setState` ou navegação após operações assíncronas.
- Serialização JSON direta em `SharedPreferences`.

Não foram coletadas métricas de FPS, uso de memória/RAM ou cold start em profiler ou em dispositivo físico. Qualquer medição futura deve ser registrada com modelo do aparelho, versão do Android, modo de build e quantidade de execuções.

## 9. Testes

`test/widget_test.dart` usa `SharedPreferences` com valores simulados e limpa estado entre cenários. O conjunto contém 16 casos: 14 testes de widget e 2 testes unitários.

1. Permanência da Splash e seleção posterior da Login.
2. Espera pela restauração local antes do roteamento.
3. Recuperação após falha de inicialização e nova tentativa.
4. Jornada completa de aluguel, persistência e cancelamento.
5. Busca em viewport compacto.
6. Filtros combinados de plataforma e estilo.
7. E-mail no Perfil e logout.
8. Alternância de temas.
9. Cores e legibilidade dos temas claro/escuro.
10. Voltar pelas abas e retorno dos detalhes.
11. Edição do Perfil e limpeza do histórico.
12. Validação de CPF e seleção/remoção de foto.
13. Bloqueio de credenciais inválidas.
14. Cadastro e abertura do Perfil com avatar por inicial.
15. Restauração de conta, perfil, preferências e detalhes serializados do aluguel.
16. Login lembrado, auto-login e limpeza da sessão no logout.

Nenhum teste comunica-se com servidor externo.

## 10. Validação e limitações

Comandos previstos para a validação final:

```bash
dart format lib test
flutter analyze && flutter test --no-pub
```

Não é correto afirmar build Android validado, execução em emulador ou dispositivo físico, instalação do APK, métricas de desempenho ou integração externa sem executar esses testes.

### Métricas pendentes de medição real

- FPS médio/pico: **não medido**
- Uso de RAM: **não medido**
- Cold start: **não medido**
- Tempo de warm start: **não medido**
- Tempo de restauração local: **não medido**

## 11. Membros do Projeto

- Antonio Moura da Costa Filho
- Enzo de Melo Cordeiro
- Marcus Vinicius Ferreira Lustosa
