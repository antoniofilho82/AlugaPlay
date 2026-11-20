# AlugaPlay — Relatório Técnico

> **Estado verificado:** 20 de novembro de 2026  
> **Escopo:** aplicação Flutter, testes de widget e recursos de abertura Android.  
> **Validação:** `flutter analyze && flutter test --no-pub` — análise limpa e 15 testes aprovados.

Este relatório descreve o código presente no repositório, não uma arquitetura futura. O AlugaPlay é um protótipo demonstrativo: autenticação, catálogo, estimativas e solicitações são locais; não há servidor, estoque real, reserva comercial nem cobrança.

## 1. Estrutura e navegação

O código Dart está organizado por responsabilidade:

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

`AlugaPlayApp` configura os temas e as rotas nomeadas. `HomeScreen` mantém as quatro abas fixas — Início, Categorias, Meus Aluguéis e Perfil — em um `IndexedStack`; a troca de aba não empilha novas rotas. Um histórico interno permite que Voltar percorra as abas visitadas antes de limpar filtros ou sair da Home.

O produto selecionado é encaminhado como argumento para Detalhes e Solicitação. As telas aceitam o argumento somente quando ele é um `Product`; se estiver ausente ou inválido, usam o primeiro item do catálogo local. Esse fallback evita erro de tipo, mas pode apresentar um produto diferente do pretendido ao abrir uma rota diretamente.

## 2. Abertura, identidade visual e tema

### Splash e inicialização

`main()` inicia a restauração local e chama `runApp` sem aguardar operações de armazenamento, permitindo que a Splash seja desenhada sem essa espera. `StartupService` compartilha o estado e a `Future` da inicialização. A Splash espera a restauração terminar antes de decidir o destino; assim, uma leitura lenta não deve encaminhar uma sessão lembrada para a Login prematuramente.

Após o primeiro frame, a barra progride de zero a um com `Curves.easeInOut` em 1.400 ms. A tela aguarda pelo menos 1.500 ms e usa `LocalAuthService.shouldAutoLogin` para ir diretamente à Home ou à Login. Um rótulo semântico `AlugaPlay` identifica a tela. O fundo Flutter é desenhado por `CustomPainter` com ondas esmeralda antialiasadas, emblema, marca e subtítulo; a imagem `assets/images/splash_bg.jpeg` está declarada, mas não é usada pela Splash atual.

O `AlugaPlayLogo` é reutilizado na Splash, Login, cadastro e recuperação de senha. Na Login, somente o texto “Criar nova conta” é clicável; a frase anterior permanece em cor neutra.

### Abertura nativa Android

O fundo nativo usa `#060D09` e centraliza `@mipmap/ic_launcher`. A imagem está configurada no `launch_background.xml` padrão e na variante `drawable-v21`; em Android 12 ou superior, `values-v31/styles.xml` usa o mesmo ícone na Splash do sistema. As variantes claro e escuro mantêm o fundo escuro.

O ícone Android é configurado por `flutter_launcher_icons` com `assets/icon/app_icon.jpeg`, como foreground adaptativo e ícone de inicialização. Os recursos já gerados no projeto não substituem a validação de um build em dispositivo.

### Paleta

`AppTheme` mantém temas cacheados e alterna o modo por `ValueNotifier<ThemeMode>`. O tema claro pastel usa:

| Elemento | Cor |
|---|---|
| Fundo e superfície base | `#E3ECE6` |
| Cards, campos e containers | `#EEF4F0` |
| Contornos | `#C8D8CE` |
| Texto principal / secundário | `#233029` / `#52645A` |
| Primária / secundária | `#2E8B57` / `#389E68` |
| Container de destaque | `#D7E7DD` |

O modo escuro usa fundo `#0F1115`, superfície `#181B20`, container `#22262E`, texto `#F8FAFC` / `#94A3B8` e acentos esmeralda. A troca de tema não anima os estilos (`Duration.zero`).

## 3. Catálogo e filtros

`mockProducts` fornece oito itens fictícios — consoles, jogos físicos e pacotes — sem carregamento de rede. As tarifas cadastradas são diárias.

Na aba Início, categoria, texto de busca, console/plataforma e estilo de jogo são combinados; um filtro não substitui os demais. As plataformas são derivadas dos produtos. Como o modelo não tem campo de gênero, os estilos são inferidos por palavras-chave no nome, descrições e especificações, e só aparecem quando há pelo menos um jogo ou pacote correspondente. O funil abre o modal Filtros rápidos; suas escolhas são aplicadas juntas, e o resumo permite limpar rapidamente os filtros específicos de console e estilo.

## 4. Contas, perfil e sessão local

`LocalAuthService` mantém contas em memória e delega a gravação ao `LocalStorageService`. O cadastro valida nome, telefone, formato de e-mail e tamanho mínimo da senha. A tela de Login autentica contra as contas cadastradas no aparelho; a recuperação de senha também é local e não envia mensagens externas.

Com “Lembrar meu acesso” ativo, a sessão guarda a opção e os e-mails necessários à restauração, não a senha. Depois da restauração, o getter `shouldAutoLogin` só retorna verdadeiro se houver uma conta atual válida. A Login pode restaurar o e-mail, mas cria o controlador da senha vazio. Logout limpa a sessão e o perfil ativo, sem apagar a conta nem o histórico de aluguéis.

**Limite de segurança:** a senha continua no registro JSON da conta para permitir a autenticação local e não é cifrada por `shared_preferences`. Este mecanismo é demonstrativo e não deve ser usado como armazenamento seguro de credenciais.

O perfil persistido inclui nome, e-mail, telefone, endereço, cidade, CPF e caminho da foto. Quando não há imagem utilizável, a aba Perfil e o modal Editar mostram a inicial do nome em branco sobre degradê esmeralda. A imagem é selecionada pela galeria; apenas seu caminho é salvo, então um arquivo removido ou inacessível aciona o fallback da inicial.

O CPF é opcional. Se informado ao serviço de autenticação ou editado no Perfil, a validação local remove pontuação, rejeita quantidade incorreta de dígitos e sequências repetidas e calcula os dois verificadores módulo 11. A tela de cadastro não solicita CPF e não há consulta externa. `isKycVerified` é um campo persistido do modelo, mas o aplicativo não implementa verificação KYC nem o marca como verificado.

## 5. Persistência local

`LocalStorageService` inicializa `SharedPreferences` e armazena snapshots JSON em chaves separadas:

| Dados | Conteúdo |
|---|---|
| Usuários | Nome, e-mail, telefone, cidade, endereço, CPF, senha, estado KYC e caminho de foto. |
| Sessão | `rememberAccess`, `rememberedEmail` e `currentUserEmail`; não contém senha. |
| Perfil | Dados de exibição e contato do jogador. |
| Preferências | Tema, notificações, modalidade e duração padrão e plataforma favorita. |
| Solicitações | Produto, datas, duração, total estimado, observações, estado, modalidade/endereço e campos adicionais do modelo. |

JSON ausente produz valores iniciais; JSON malformado ou com estrutura inesperada gera erro em vez de ser silenciosamente substituído. O armazenamento não tem criptografia, sincronização, migração de esquema nem recuperação automática de dados corrompidos.

`Rental.toJson()` e `Rental.fromJson()` suportam PIN, número de série, checklist, caução, forma de pagamento e aceite dos termos. **A tela atual de Solicitação não coleta nem atribui esses campos**: eles permanecem nos valores padrão quando o usuário cria um aluguel pela interface. O teste de persistência preenche esses campos diretamente no modelo para verificar sua serialização; isso não comprova um fluxo de preenchimento na interface. A confirmação, o cancelamento e a limpeza do histórico persistem a lista de solicitações.

## 6. Solicitação de aluguel

`RentalScreen` recebe o produto da rota, escolhe datas de início e término, modalidade, endereço de delivery e observações, calcula uma estimativa e pede confirmação. As datas são normalizadas para meia-noite; períodos inferiores a um dia são bloqueados. Produtos com tarifa semanal seriam rateados por dia, mas todos os produtos do catálogo atual têm tarifa diária.

A confirmação cria um `Rental` com datas, duração, estimativa, observações e dados de entrega e grava a lista local. A interface informa que não há cobrança real. A aba Meus Aluguéis ordena os registros do mais recente para o mais antigo, permite cancelar uma solicitação e mantém o estado vazio quando não há registros.

## 7. Comentários e manutenção

A revisão percorreu os arquivos Dart de `lib/` e `test/widget_test.dart`. Foram retirados comentários que apenas repetiam nomes de campos, widgets ou ações evidentes; comentários mantidos ou acrescentados esclarecem decisões menos óbvias: restauração de sessão sem senha na sessão, validação local de CPF e limites de KYC, serialização de solicitações, filtros combinados, fallback do avatar, inicialização da Splash e paleta pastel.

A revisão também corrigiu uma condição de corrida encontrada na inicialização: a Splash podia consultar o auto-login antes de terminar a restauração local. Agora ela aguarda a `Future` de inicialização apenas quando os dados ainda não estão prontos. Foi corrigida ainda a variante nativa Android `drawable-v21`, que não mostrava o ícone, e a configuração Android 12+, que mantinha o ícone transparente.

## 8. Testes e validação

`test/widget_test.dart` inicializa `SharedPreferences` com valores simulados e limpa estado entre cenários. Os 15 testes cobrem:

1. Identidade e progresso da Splash e redirecionamento para Login.
2. Espera da Splash pela restauração local antes da escolha de rota.
3. Jornada de aluguel, persistência básica e cancelamento.
4. Busca em viewport compacto.
5. Filtros combinados de plataforma/estilo, legibilidade dos chips e limpeza.
6. Exibição do e-mail no Perfil e logout.
7. Alternância entre os temas.
8. Cores do tema claro pastel.
9. Histórico de abas e retorno dos detalhes.
10. Edição do Perfil, preferências e limpeza do histórico.
11. Validação de CPF e seleção/remoção de foto.
12. Rejeição de credenciais incorretas.
13. Cadastro, entrada e fallback do avatar pela inicial.
14. Restauração de conta, perfil, preferências e campos de aluguel serializados.
15. Auto-login após restauração e limpeza da sessão no logout.

Formatação: `dart format lib test` — 23 arquivos Dart verificados.

Validação executada:

```text
Analyzing AlugaPlay...
No issues found! (ran in 2.3s)
00:00 +0: loading C:/Users/anton/OneDrive/Documentos/Estudos/FACULDADE/Flutter/AlugaPlay/test/widget_test.dart
00:00 +0: Splash screen navigates to login after its display interval
00:01 +1: Splash waits for local restoration before selecting a route
00:01 +2: customer can rent a selected catalog product end to end
00:03 +3: home search filters products on a compact screen without overflow
00:04 +4: quick filters combine platform and game style and can clear
00:05 +5: login email appears in profile and sign out returns to login
00:06 +6: user can switch between light and dark themes
00:07 +7: light theme uses soft surfaces and readable text colors
00:07 +8: system back follows tab history and pops product details
00:08 +9: profile edits player settings and clears rental history
00:09 +10: profile validates CPF and allows selecting and removing photo
00:10 +11: local login blocks accounts that do not authenticate
00:10 +12: new account registers and opens the authenticated profile
00:11 +13: local storage restores account, preferences, and rental details
00:11 +14: remembered login restores home and logout clears the session
00:12 +15: All tests passed!
```

Não foi executado build Android nem validação em dispositivo físico/emulador.

## 9. Membros do Projeto

- Antonio Moura da Costa Filho
- Enzo de Melo Cordeiro
- Marcus Vinicius Ferreira Lustosa
