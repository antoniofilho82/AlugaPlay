# AlugaPlay — Documentação Técnica de Engenharia de Software

> **Versão documentada:** 15 de novembro de 2026  
> **Escopo documentado:** aplicação Flutter, seis testes de widget e recursos visuais nativos Android.  
> **Validação executada:** `flutter analyze && flutter test --no-pub`.
> **Equipe:** Antonio Moura da Costa Filho, Enzo de Melo Cordeiro e Marcus Vinicius Ferreira Lustosa

Este documento descreve o estado implementado no código inspecionado. As telas e regras descritas são demonstrativas: o projeto ainda não executa autenticação, pagamento ou persistência remota.

## 1. Concepção do Projeto, Problema e Decisões Arquiteturais

### 1.1 Problema e objetivo

O AlugaPlay propõe uma experiência para descobrir e solicitar a locação de consoles, jogos físicos e pacotes de acessórios. O problema de produto é tornar mais acessível experimentar equipamentos de jogos sem exigir sua compra definitiva. A interface organiza catálogo, especificações e período de locação, apresentando um valor estimado antes da confirmação.

O público-alvo da primeira versão é formado por jogadores interessados em testar diferentes plataformas e por pessoas que desejam alugar conjuntos prontos para sessões individuais ou em grupo.

### 1.2 Escopo do MVP — Fase 1

A versão entregue é um protótipo front-end mobile com foco de uso em Android. O fluxo funcional implementado inclui splash, login demonstrativo, exploração e filtragem do catálogo, detalhes do produto, estimativa de aluguel, confirmação local e abas de solicitações e perfil.

O app usa conteúdo fictício declarado no código e estado em memória. “Confirmação” significa registrar um objeto na lista local enquanto o processo está ativo; não significa reserva real, pagamento, disponibilidade de estoque ou operação comercial. A arquitetura separa as telas e as regras de domínio para permitir que persistência e integrações sejam acrescentadas futuramente sem transformar o protótipo em um backend.

### 1.3 Decisões técnicas

| Decisão | Aplicação atual | Motivo e consequência |
|---|---|---|
| Modularização por responsabilidade | `app/`, `theme/`, `routes/`, `models/`, `data/`, `components/`, `screens/` | Isola configuração, regras, conteúdo e interface; facilita alterações localizadas e trabalho paralelo. |
| Estado Flutter local | `StatefulWidget`, `setState`, `IndexedStack`, `ValueNotifier<ThemeMode>` | Adequado ao escopo do protótipo: estado de tela local e tema reativo, sem pacote externo de gerenciamento de estado. |
| Aparência e desempenho da troca de tema | Temas cacheados e `themeAnimationDuration: Duration.zero` | Reutiliza as instâncias de `ThemeData` e elimina a transição animada durante a alternância. |
| Estado demonstrativo estático | `UserProfile.currentUser`, `Rental.localRequests` | Facilita compartilhar os dados entre telas sem serviço, mas não persiste após encerrar o app e não é uma estratégia de produção para múltiplos usuários. |
| Rotas nomeadas nativas | `MaterialApp.routes` e `Navigator.pushNamed` | Mantém os caminhos centralizados e transfere o produto selecionado por `RouteSettings.arguments`. |
| Formatação em Dart puro | `Product.formattedPrice`, `_formatDate`, `_formatCurrency` | Evita dependência de `intl` na Fase 1. A implementação atual cobre valores e datas nos formatos simples usados no protótipo. |
| Catálogo local constante | `mockProducts` | Permite validar filtros e jornada sem API, rede ou banco de dados. |
| Biblioteca visual declarada | Imports `package:material_ui/material_ui.dart` | Fornece widgets Material/Flutter usados pelo app. |

O estado é deliberadamente simples: a Home reconstrói com `setState`, mantém as quatro abas sob um `IndexedStack` e atualiza depois da volta da rota de detalhes. A lista estática de aluguéis não implementa isolamento por usuário nem sincronização concorrente; essas necessidades pertencem às fases futuras.

### 1.4 Árvore do código de aplicação

```text
AlugaPlay/
├── pubspec.yaml
├── assets/
│   ├── images/
│   └── icons/
│       └── alugaplay_icon.png
├── lib/
│   ├── main.dart
│   ├── app/
│   │   └── app.dart
│   ├── theme/
│   │   └── app_theme.dart
│   ├── routes/
│   │   └── app_routes.dart
│   ├── models/
│   │   ├── product.dart
│   │   ├── rental.dart
│   │   └── user_profile.dart
│   ├── data/
│   │   └── mock_products.dart
│   ├── components/
│   │   ├── primary_button.dart
│   │   ├── category_item.dart
│   │   └── product_card.dart
│   └── screens/
│       ├── splash/splash_screen.dart
│       ├── login/login_screen.dart
│       ├── home/home_screen.dart
│       ├── product_details/product_details_screen.dart
│       └── rental/rental_screen.dart
└── test/
    └── widget_test.dart
```

### 1.5 Fluxo de navegação e dados

```text
AlugaPlayApp
  └─ AppRoutes.splash
       └─ (Timer de 2,5 s; pushReplacementNamed)
            LoginScreen
              └─ Entrar / updateFromLoginEmail
                   └─ pushReplacementNamed(AppRoutes.home)
                        HomeScreen — IndexedStack
                          ├─ Início: busca + categoria + catálogo
                          │    └─ pushNamed(AppRoutes.productDetails,
                          │                 arguments: Product selecionado)
                          │         ProductDetailsScreen
                          │           └─ pushNamed(AppRoutes.rental,
                          │                        arguments: mesmo Product)
                          │                RentalScreen
                          │                  └─ Rental.localRequests.add(...)
                          │                     + AlertDialog de confirmação
                          │                     + popUntil(AppRoutes.home)
                          ├─ Categorias: seleciona filtro e volta à Início
                          ├─ Meus Aluguéis: lista reversa / cancelar
                          └─ Perfil: dados de UserProfile / atalhos / logout
                               Histórico das abas: _tabHistory + PopScope
```

O objeto `Product` é passado como argumento, não reconstruído a partir de identificador. `HomeScreen._openProduct` aguarda o retorno da tela de detalhes e atualiza o estado se ainda estiver montada. `ProductDetailsScreen` repassa a instância recebida à tela de aluguel. Após a confirmação, `popUntil` fecha as telas intermediárias até encontrar a rota da Home ou a primeira rota.

As trocas de aba pela barra, atalhos do Perfil e ações de retorno passam por `_navigateToTab`. A aba anterior é adicionada ao histórico sem duplicatas consecutivas; o botão Voltar consome a última aba visitada antes de retornar ao início ou limpar filtros. Selecionar Início manualmente e encerrar a sessão limpa o histórico.

## 2. Design System, Tema Global e Identidade Visual no Código

### 2.1 Paletas oficiais

| Modo | Elemento | Cor |
|---|---|---|
| Claro | Fundo cinza-azulado | `#EEF2F6` |
| Claro | Superfícies e cards | `#FFFFFF` |
| Claro | Containers e bordas | `#E2E8F0` / `#CBD5E1` |
| Claro | Verde primário e profundo | `#16A34A` / `#15803D` |
| Claro | Texto principal e secundário | `#0F172A` / `#475569` |
| Escuro | Fundo grafite | `#0F1115` |
| Escuro | Superfícies e cards | `#181B20` |
| Escuro | Containers e bordas | `#22262E` / `#2E3440` |
| Escuro | Verde primário e acento | `#16A34A` / `#22C55E` |
| Escuro | Texto principal e secundário | `#F8FAFC` / `#94A3B8` |

As telas aplicam variações de transparência com `withValues(alpha: ...)`; elas derivam das cores e semânticas dos dois temas.

### 2.2 `AppTheme` e `ThemeData`

`lib/theme/app_theme.dart` contém a classe utilitária `AppTheme`, cujo construtor é privado. As cores e os raios (`radiusMedium = 12`, `radiusLarge = 16`) são constantes estáticas. `themeModeNotifier` é um `ValueNotifier<ThemeMode>` iniciado em `ThemeMode.system`; `toggleTheme` alterna explicitamente entre claro e escuro, notificando o app.

`lightTheme` e `darkTheme` são instâncias `static final`, construídas uma vez por `_buildLightTheme()` e `_buildDarkTheme()` e reutilizadas nas mudanças de aparência. A construção compartilhada cria o `ColorScheme`, configura superfícies, containers, contornos, tipografia e componentes Material (botões, campos, cards, ícones, chips, divisores, `AppBar`, navegação, `SnackBar` e diálogos). O tema claro aplica borda `#CBD5E1` nos cards.

`AlugaPlayApp` observa o notifier com `ValueListenableBuilder<ThemeMode>` e entrega o modo atual a `MaterialApp`. `themeAnimationDuration: Duration.zero` faz a troca ocorrer sem animar centenas de estilos nas telas mantidas pelo `IndexedStack`.

Trechos representativos:

```dart
static final ThemeData darkTheme = _buildDarkTheme();
static final ThemeData lightTheme = _buildLightTheme();
```

```dart
themeMode: mode,
themeAnimationDuration: Duration.zero,
```

O fragmento destaca o cache e a aplicação sem animação; as paletas completas estão tabeladas nesta seção.

### 2.3 Responsividade e contenção de texto

As telas usam técnicas complementares para limitar estouros:

- `Expanded` divide o espaço disponível em `Row` e permite que texto ceda espaço a ícones ou ações.
- `Flexible` permite que botões e valores ocupem largura proporcional.
- `TextOverflow.ellipsis` e `maxLines` controlam nomes, badges, descrições curtas e rótulos extensos.
- `Wrap` no destaque e no rodapé de cadastro permite que elementos quebrem para a linha seguinte.
- `SingleChildScrollView` protege formulários longos, detalhes e perfil contra alturas menores e teclado virtual.
- `CustomScrollView` com slivers mantém a Home rolável e adequada à listagem.
- `LayoutBuilder` na Solicitação empilha cartões de data quando a largura disponível é menor que 360 pixels.
- A faixa de categorias usa `ListView` horizontal.

O teste de viewport 360×800 cobre a busca e verifica ausência de exceção no cenário testado. Não é uma comprovação de que todas as telas, orientações, escalas de fonte ou estados de teclado estejam livres de overflow.

## 3. Anatomia do Código — Entrada, App e Roteamento

### 3.1 `lib/main.dart`

Arquivo de entrada do Flutter. Importa `AlugaPlayApp` e o pacote de widgets e define a função `main()`:

```dart
void main() {
  runApp(const AlugaPlayApp());
}
```

O `const` permite construir a raiz sem estado inicial mutável próprio.

### 3.2 `lib/app/app.dart` — `AlugaPlayApp`

`AlugaPlayApp` estende `StatelessWidget`. Seu único método de composição é `build`, que retorna `MaterialApp`:

- define o título `AlugaPlay`;
- desativa a faixa de depuração;
- configura os temas cacheados `AppTheme.lightTheme` e `AppTheme.darkTheme`, acompanhados pelo modo atual do notifier;
- escolhe `AppRoutes.splash` como `initialRoute`;
- entrega o mapa `AppRoutes.routes`.

O `ValueListenableBuilder<ThemeMode>` reconstrói o `MaterialApp` quando `themeModeNotifier` muda. Os temas claros e escuros são instâncias cacheadas, e `themeAnimationDuration: Duration.zero` aplica a aparência imediatamente.

### 3.3 `lib/routes/app_routes.dart` — `AppRoutes`

A classe não pode ser instanciada (`AppRoutes._()`). As cinco constantes nomeadas e as telas construídas pelo getter `routes` são:

| Constante | Caminho | Widget |
|---|---|---|
| `splash` | `/` | `SplashScreen` |
| `login` | `/login` | `LoginScreen` |
| `home` | `/home` | `HomeScreen` |
| `productDetails` | `/product-details` | `ProductDetailsScreen` |
| `rental` | `/rental` | `RentalScreen` |

Trecho real:

```dart
static Map<String, WidgetBuilder> get routes => {
  splash: (_) => const SplashScreen(),
  login: (_) => const LoginScreen(),
  home: (_) => const HomeScreen(),
  productDetails: (_) => const ProductDetailsScreen(),
  rental: (_) => const RentalScreen(),
};
```

As rotas não declaram builders com parâmetros de produto. O contexto de rota fornece `RouteSettings.arguments`, validado em cada tela que consome `Product`.

### 3.4 Recursos nativos Android

O `AndroidManifest.xml` exibe o rótulo `AlugaPlay`. O ícone adaptativo referencia o foreground vetorial `drawable/ic_launcher_foreground.xml` e o fundo sólido `drawable/ic_launcher_background.xml` em `#13171D`; não há PNGs de foreground por densidade competindo com o vetor. Os `ic_launcher.png` de densidade permanecem como legado para versões anteriores ao Android 8.

O `LaunchTheme` usa fundo sólido que acompanha o modo claro ou escuro. Para Android 12+, os estilos definem `android:windowSplashScreenAnimatedIcon` como transparente e configuram `android:windowSplashScreenBackground` com o fundo do modo, evitando uma segunda splash com ícone antes da SplashScreen Flutter.

## 4. Anatomia do Código — Modelos de Domínio, Regras e Catálogo

### 4.1 `lib/models/product.dart` — `Product`

`Product` é um modelo imutável: construtor `const`, atributos `final` e nenhuma operação de mutação. Os parâmetros obrigatórios são `id`, `name`, `category`, `platform`, `shortDescription`, `fullDescription`, `rentalPrice`, `billingUnit`, `icon`, `specs`, `includedItems` e `demoAvailabilityLabel`. `imageAsset` é opcional e `isFeatured` tem padrão `false`.

O construtor contém um `assert` que restringe `category` a `Consoles`, `Jogos` ou `Pacotes`. Essa é uma assertiva de desenvolvimento, não uma validação de dados remotos.

#### Algoritmo de `formattedPrice`

O getter produz uma string `R$` com duas casas decimais:

```dart
String get formattedPrice {
  final parts = rentalPrice.toStringAsFixed(2).split('.');
  final integerPart = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return 'R\$ $integerPart,${parts.last}';
}
```

Passo a passo:

1. `toStringAsFixed(2)` arredonda a representação para duas casas decimais.
2. `split('.')` separa parte inteira e casas decimais.
3. A expressão regular `\B(?=(\d{3})+(?!\d))` procura posições antes de grupos de três dígitos, exceto no início, e insere `.` como separador de milhar.
4. A interpolação concatena prefixo Real, parte inteira agrupada, vírgula e decimais.

O algoritmo é suficiente para os preços positivos do catálogo demonstrativo. Não implementa internacionalização, moeda variável ou regras para valores negativos.

### 4.2 `lib/models/rental.dart` — `Rental`

`Rental` é um registro imutável criado com construtor `const`. Campos:

| Campo | Tipo | Significado |
|---|---|---|
| `id` | `String` | Identificador local gerado ao confirmar. |
| `product` | `Product` | Instância selecionada na jornada. |
| `startDate`, `endDate` | `DateTime` | Datas normalizadas escolhidas para o aluguel. |
| `totalDays` | `int` | Diferença em dias inteiros. |
| `estimatedTotal` | `double` | Estimativa, sem cobrança. |
| `notes` | `String` | Observação opcional, sem espaços externos após confirmação. |
| `status` | `String` | Estado demonstrativo com valor inicial `Solicitação demonstrativa enviada`. |

`static final List<Rental> localRequests = [];` cria uma lista estática compartilhada por todas as instâncias e telas. `final` impede trocar a referência da lista, mas permite adicionar e remover registros. Ela é volátil: fechar o processo apaga os dados.

### 4.3 `lib/models/user_profile.dart` — `UserProfile`

`UserProfile` é imutável por instância; seus campos finais são `displayName`, `email`, `gamerTag`, `city` e `accountBadge`. `defaultProfile` contém o jogador e e-mail demonstrativos. `currentUser` é uma referência estática mutável à sessão atual.

#### `updateFromLoginEmail`

Trecho real:

```dart
static void updateFromLoginEmail(String rawEmail) {
  final email = rawEmail.trim();
  if (email.isEmpty) {
    currentUser = defaultProfile;
    return;
  }

  final localPart = email.split('@').first;
  final displayName = localPart
      .replaceAll(RegExp(r'[._]+'), ' ')
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map(
        (part) => '${part.substring(0, 1).toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
  // Atualiza currentUser com o nome, e-mail, tag e dados demonstrativos.
}
```

O método remove espaços externos; em entrada vazia restaura o perfil padrão. Caso contrário, usa a parte antes do primeiro `@`, substitui sequências de ponto e underscore por espaço, divide por espaços, descarta segmentos vazios e transforma a primeira letra de cada segmento em maiúscula. A gamer tag é `@` mais o trecho local em minúsculas. O e-mail preservado é a versão aparada (`trim`), não necessariamente idêntica ao texto digitado com espaços ao redor. A função não valida sintaxe de e-mail nem trata explicitamente aliases com `+`.

`reset()` apenas aponta `currentUser` novamente para `defaultProfile`; o logout da Home também limpa `Rental.localRequests`.

### 4.4 `lib/data/mock_products.dart` — `mockProducts`

`mockProducts` é uma lista constante de oito valores `Product`, sem carregamento de rede:

| ID | Nome resumido | Categoria | Plataforma | Tarifa | Especificações / itens incluídos |
|---|---|---|---|---|---|
| `ps5-disc` | PlayStation 5 com Leitor | Consoles | PlayStation 5 | R$ 89,90/dia | SSD, 4K e Blu-ray; console, DualSense e cabos. |
| `xbox-series-x` | Xbox Series X | Consoles | Xbox Series X | R$ 84,90/dia | SSD, 4K e compatibilidade Xbox; console, controle e cabos. |
| `switch-oled` | Nintendo Switch OLED | Consoles | Nintendo Switch | R$ 59,90/dia | Tela OLED de 7", modo portátil/TV; console, Joy-Con, dock e cabos. |
| `spider-man-2` | Marvel's Spider-Man 2 | Jogos | PlayStation 5 | R$ 24,90/dia | Mídia física, aventura solo e compatibilidade PS5; disco e estojo. |
| `zelda-totk` | The Legend of Zelda: Tears of the Kingdom | Jogos | Nintendo Switch | R$ 19,90/dia | Mídia física, aventura solo e compatibilidade Switch; cartucho e estojo. |
| `ps5-extra-dualsense` | Pacote PS5 + Controle DualSense Extra | Pacotes | PlayStation 5 | R$ 109,90/dia | PS5 com leitor, dois controles e 4K; console, controles e cabos. |
| `xbox-games-pack` | Pacote Xbox Series X + 2 Jogos Físicos | Pacotes | Xbox Series X | R$ 119,90/dia | Console, dois jogos e controle; console, controle, jogos e cabos. **Destaque.** |
| `switch-multiplayer-pack` | Pacote Nintendo Switch OLED + Kit Multiplayer e Case | Pacotes | Nintendo Switch | R$ 94,90/dia | Switch OLED, acessórios multiplayer e case; console, Joy-Con, kit e case. |

Cada valor contém descrições curtas e completas, ícone Material, especificações, itens incluídos e rótulo de disponibilidade demonstrativa. Todos estão marcados `por dia`; portanto, a lógica para unidade semanal ainda não aparece representada por produto nos dados.

## 5. Anatomia do Código — Componentes Reutilizáveis

### 5.1 `lib/components/primary_button.dart` — `PrimaryButton`

Widget sem estado que centraliza um botão elevado:

- `label`: texto de ação obrigatório;
- `onPressed`: callback anulável; `null` desabilita o botão;
- `icon`: ícone opcional;
- `isCompact`: reduz altura, espaçamento, ícone e tipografia.

A altura é 48 ou 38 pixels. O conteúdo é uma `Row` de largura mínima; o rótulo ocupa `Flexible`, limita-se a uma linha e usa reticências. O `ElevatedButton` aplica as cores da paleta e borda arredondada.

### 5.2 `lib/components/category_item.dart` — `CategoryItem`

Widget sem estado com `label`, `icon`, `isSelected` e callback obrigatório `onTap`. A interação é feita por `InkWell`; um `AnimatedContainer` de 180 ms muda a superfície para a cor de ação quando selecionado. O ícone muda entre texto primário e acento conforme o estado. A largura permanece intrínseca ao rótulo, e a Home hospeda os itens em lista horizontal rolável.

### 5.3 `lib/components/product_card.dart` — `ProductCard`

Recebe o objeto `Product` e `onTap`. A hierarquia principal é:

```text
Card
└─ InkWell(onTap)
   └─ Padding
      └─ Column
         ├─ imagem local substituída por ícone + badge de categoria
         ├─ nome (1 linha, ellipsis)
         ├─ plataforma
         ├─ descrição curta (2 linhas, ellipsis)
         └─ Row
            ├─ preço e unidade (Expanded)
            └─ PrimaryButton compacto “Detalhes”
```

Não exibe imagem carregada da rede; usa o ícone associado ao produto. O badge mostra categoria, não uma disponibilidade dinâmica. Tanto o cartão quanto o botão reutilizam a mesma callback, permitindo abrir os detalhes pelos dois pontos de toque.

## 6. Anatomia do Código — Implementação Detalhada das Telas

### 6.1 `lib/screens/splash/splash_screen.dart` — `SplashScreen`

`SplashScreen` é `StatefulWidget`; `_SplashScreenState` usa `SingleTickerProviderStateMixin`. Campos:

- `_controller`: `AnimationController` de 900 ms;
- `_fadeAnimation`: curva aplicada à opacidade;
- `_scaleAnimation`: tween de escala `0.88` a `1`;
- `_timer`: temporizador anulável de 2.500 ms.

Em `initState()`, cria-se uma `CurvedAnimation` com `Curves.easeOutCubic`, compartilhada entre fade e escala, e inicia-se o controlador. O callback do temporizador verifica `mounted` antes de usar o `context` para `pushReplacementNamed(AppRoutes.login)`. Em `dispose()`, cancela o temporizador e descarta o controlador.

O emblema Flutter usa o quadrado interno e o controle gamer nas cores do ícone adaptativo Android. No Android 12+, a splash nativa mantém fundo correspondente ao tema e ícone animado transparente, evitando exibir um segundo emblema antes do primeiro frame Flutter.

Árvore do `build`:

```text
Scaffold(background)
└─ SafeArea
   └─ Padding
      └─ Column
         ├─ Spacer
         ├─ FadeTransition
         │  └─ ScaleTransition
         │     └─ marca + nome AlugaPlay + subtítulo
         ├─ Spacer
         └─ indicador linear de progresso
```

### 6.2 `lib/screens/login/login_screen.dart` — `LoginScreen`

`LoginScreen` é stateful. `_LoginScreenState` guarda as cinco constantes locais da paleta, `_emailController`, `_passwordController` e `_obscurePassword`.

- `dispose()` encerra os dois `TextEditingController`.
- `_enterDemoMode()` fecha o teclado, chama `UserProfile.updateFromLoginEmail(_emailController.text)` e substitui a Login pela Home com `pushReplacementNamed(AppRoutes.home)`.
- `_showPrototypeNotice(featureName)` exibe um `SnackBar` informando que a ação não está integrada.
- O botão de senha alterna `_obscurePassword` dentro de `setState`, atualizando `obscureText`, ícone e tooltip.

A árvore da interface é `Scaffold → SafeArea → LayoutBuilder → SingleChildScrollView → ConstrainedBox → Center → Column`. O limite máximo do conteúdo é 420 pixels. O formulário inclui e-mail, senha, aviso de recuperação não integrada, botão “Entrar” e convite de criação de conta demonstrativa. `Wrap` organiza os elementos finais em larguras menores.

Não há validação de credenciais ou autenticação: submeter a senha ou tocar em “Entrar” realiza a mesma entrada demonstrativa.

### 6.3 `lib/screens/home/home_screen.dart` — `HomeScreen`

#### Estado e ciclo de vida

`_HomeScreenState` mantém:

- `_searchController`;
- `_selectedTab`, índice inicial 0;
- `_searchQuery`, inicialmente vazio;
- `_selectedCategory`, inicialmente `Todos`;
- listas e mapas constantes de categorias e ícones.

`dispose()` encerra o controlador de busca. A mudança de aba, campo de busca e seleção de categoria usam `setState`.

#### Getter `_filteredProducts`

O getter normaliza a busca com `trim().toLowerCase()`. Para cada produto, verifica simultaneamente:

1. categoria igual à selecionada, a menos que seja `Todos`;
2. consulta vazia ou contida no nome ou plataforma em minúsculas.

Só mantém o produto quando `matchesCategory && matchesSearch`. Assim, filtros por texto e categoria se intersectam, em vez de um substituir o outro.

#### `_openProduct`

```dart
Future<void> _openProduct(Product product) async {
  await Navigator.of(context)
      .pushNamed(AppRoutes.productDetails, arguments: product);
  if (!mounted) return;
  setState(() {});
}
```

Todos os cartões e o destaque enviam a instância que representam. O método aguarda a rota voltar; a verificação de `mounted` impede `setState` depois da desmontagem.

#### Abas e árvores

O `build` principal retorna:

```text
Scaffold
├─ IndexedStack(index: _selectedTab)
│  ├─ _buildHomeTab()
│  ├─ _buildCategoriesTab()
│  ├─ _buildRentalsTab()
│  └─ _buildProfileTab()
└─ NavigationBar
   ├─ Início
   ├─ Categorias
   ├─ Meus aluguéis
   └─ Perfil
```

`IndexedStack` mantém as subárvores montadas ao alternar, preservando estados locais. As abas são seleções internas da Home; não criam rotas separadas.

**Início:** `_buildHomeTab()` cria `CustomScrollView` e slivers para cabeçalho, busca, faixa de categorias, destaque opcional, pacotes opcionais, contagem do catálogo e lista filtrada. O destaque desaparece com busca ou categoria diferente de `Todos`; os pacotes aparecem quando a busca está vazia e a categoria é `Todos` ou `Pacotes`. A faixa “Pacotes Especiais” vem da lista completa de produtos da categoria e não da busca, conforme o comportamento atual. O estado vazio apresenta “Limpar filtros”.

**Categorias:** `_buildCategoriesTab()` apresenta três categorias com contagem calculada sobre `mockProducts`. `_buildCategoryCard()` dispara `_selectCategory`, que define a categoria e seleciona a aba Início.

**Meus Aluguéis:** `_buildRentalsTab()` gera `Rental.localRequests.reversed.toList()`, mostrando o registro mais novo primeiro. Há cabeçalho com contagem e estado vazio com botão para retornar à Home. Cada `_buildRentalCard()` apresenta ícone, nome, status, datas, duração, preço estimado, observações opcionais e botão de cancelamento. `_cancelRental()` remove a instância selecionada com `setState` e exibe `SnackBar`. `_formatDate()` usa `padLeft(2, '0')` para dia e mês; `_formatCurrency()` troca ponto decimal por vírgula.

**Perfil:** `_buildProfileTab()` lê `UserProfile.currentUser` e a contagem de `Rental.localRequests`. Apresenta nome, gamer tag, e-mail, cidade e selo, além de dois resumos e atalhos para as abas. `_profileDetail`, `_buildProfileSummary` e `_buildProfileShortcut` são subárvores auxiliares. `_signOut()` limpa histórico e solicitações, restaura o perfil e substitui a Home por `AppRoutes.login`.

#### Histórico de abas e botão Voltar

`_tabHistory` é uma pilha local de índices. `_navigateToTab(index)` ignora a aba atual, registra a anterior sem repetir entradas consecutivas e atualiza `_selectedTab`. Barra inferior, atalhos do Perfil e ação “Explorar Catálogo” usam o mesmo método; a seleção de categoria também retorna à Home por esse fluxo. A escolha manual da aba Início na barra e o logout limpam a pilha.

`PopScope` permite o pop normal somente quando a Home está na aba Início, sem histórico e sem filtros. Caso contrário, intercepta o botão Voltar: restaura a última aba visitada, retorna ao início se não houver histórico, ou limpa busca e categoria quando a Home já está selecionada. Isso permite voltar de Meus Aluguéis para Categorias e, em seguida, para Início sem fechar a tela.

### 6.4 `lib/screens/product_details/product_details_screen.dart` — `ProductDetailsScreen`

Widget sem estado: obtém `ModalRoute.of(context)?.settings.arguments`; se o valor for `Product`, usa a instância. Caso contrário, escolhe `mockProducts.first` quando a lista não está vazia; só produz `null` se o catálogo estiver vazio.

Essa escolha constitui um fallback funcional, mas silencioso: argumentos ausentes ou inválidos podem mostrar os detalhes de um produto que o usuário não escolheu. `_buildMissingProduct` é renderizado apenas quando não existe item no catálogo, e oferece retorno com `maybePop()`.

Com produto válido, o corpo é `SafeArea → SingleChildScrollView → Column`, com:

- `_buildProductHero`: ícone ou asset opcional, fallback para ícone em erro de asset, e badges de categoria/plataforma;
- nome, aviso demonstrativo e descrição completa;
- seção de especificações apenas quando `specs.isNotEmpty`;
- seção de itens incluídos com `_buildListCard` ou estado vazio;
- `_buildListCard`: linhas com ícone, texto flexível e divisórias.

`bottomNavigationBar` fica fora do corpo rolável e mostra tarifa/unidade junto de “Solicitar Aluguel”. O callback chama `pushNamed(AppRoutes.rental, arguments: product)`, mantendo a instância que a tela recebeu.

### 6.5 `lib/screens/rental/rental_screen.dart` — `RentalScreen`

#### Estado e ciclo de vida

Campos:

- `_startDate` e `_endDate`, inicializados em `initState`;
- `_notesController`, descartado em `dispose`;
- `_dateErrorMessage`, atualizado após seleção e validação.

O período inicial é de amanhã até três dias depois. `_normalizeDate` cria `DateTime(date.year, date.month, date.day)`, descartando horas, minutos, segundos e milissegundos. Isso torna a diferença em `.inDays` baseada nos dias de calendário, em vez de frações de 24 horas.

#### Produto da rota e fallback

`_productFromRoute()` aceita o argumento somente quando `arguments is Product`. Se inválido, usa o primeiro elemento de `mockProducts`; se a lista estiver vazia, retorna `null`. Assim como em Detalhes, a recuperação evita erro de tipo, mas um argumento inválido pode levar a uma solicitação de produto inesperado.

#### Datas e `showDatePicker`

`_selectDate(isStartDate:)` abre o seletor entre hoje normalizado e 365 dias à frente. O builder aplica `ColorScheme.dark` e `DialogThemeData` próprios. Se o usuário cancelar, ou se o widget não estiver montado após o `await`, não atualiza a tela. A data escolhida é normalizada, gravada com `setState` e validada.

`_validateDates()` calcula `normalizedEnd.difference(normalizedStart).inDays`; diferenças menores que um dia definem `_dateErrorMessage`. `_confirmRequest` repete a checagem antes de registrar, de modo que datas iguais ou invertidas não gerem solicitação.

#### Cálculo de estimativa

```dart
double _estimatedTotal(Product product) {
  if (_totalDays < 1) return 0;
  final dailyRate = product.billingUnit.toLowerCase().contains('semana')
      ? product.rentalPrice / 7.0
      : product.rentalPrice;
  return _totalDays * dailyRate;
}
```

Para unidade semanal, divide a tarifa por sete e multiplica pelos dias selecionados; para as unidades atuais do catálogo, usa a tarifa diária diretamente. O resultado é apresentado com `toStringAsFixed(2)` e vírgula decimal. Não há regras de arredondamento comercial adicionais nem cobertura de teste para uma tarifa semanal.

#### Registro e retorno

`_confirmRequest(product)` cria `Rental` com ID baseado em `microsecondsSinceEpoch`, datas normalizadas, duração, estimativa e observações aparadas. Adiciona o objeto em `Rental.localRequests`, então exibe `AlertDialog` com resumo e aviso de armazenamento local. O botão fecha o diálogo e usa:

```dart
Navigator.of(context).popUntil(
  (route) =>
      route.settings.name == AppRoutes.home || route.isFirst,
);
```

A alternativa `route.isFirst` evita continuar procurando indefinidamente se a Home não existir na pilha. O formulário é uma `SingleChildScrollView`; `LayoutBuilder` empilha os cartões de data abaixo de 360 pixels e os coloca lado a lado a partir desse limite. O CTA fixo “Confirmar Solicitação” fica na `bottomNavigationBar`.

## 7. Engenharia dos Testes Automatizados

O arquivo `test/widget_test.dart` contém seis testes de widget. `setUp` e `tearDown` restauram `ThemeMode.system`, limpam `Rental.localRequests` e chamam `UserProfile.reset()`, evitando estado compartilhado entre casos.

O tempo da splash é avançado com `tester.pump(const Duration(milliseconds: 2600))`, sem aguardar 2,6 segundos reais. Os testes usam `pumpAndSettle()` após navegações e animações.

### Cenário 1 — Splash para Login

1. Monta `AlugaPlayApp`.
2. Confirma ícone e subtítulo da splash.
3. Avança 2.600 ms.
4. Verifica textos de entrada na Login.

### Cenário 2 — Jornada de aluguel e cancelamento

1. Avança a splash e toca em “Entrar”.
2. Confirma `HomeScreen`.
3. Rola até `Marvel's Spider-Man 2`, diferente do primeiro item de fallback.
4. Confere nome, categoria, plataforma, descrição e preço na tela de detalhes.
5. Solicita aluguel e confere os três dias padrão e o total calculado.
6. Confirma, verifica o diálogo e retorna ao catálogo.
7. Valida o conteúdo de `Rental.localRequests`.
8. Abre Meus Aluguéis, confere o produto e cancela a solicitação.
9. Verifica o estado vazio e a lista limpa.

### Cenário 3 — Busca em viewport compacto

Define `tester.view.physicalSize = const Size(360, 800)` e `devicePixelRatio = 1`, registrando o reset com `addTearDown`. Depois entra na Home, pesquisa `Tears of the Kingdom` e verifica que o resultado esperado aparece, o jogo Marvel não aparece e `tester.takeException()` retorna `null`.

### Cenário 4 — Sessão do perfil e logout

Preenche `lucas@alugaplay.com` na Login, entra, abre Perfil e confere e-mail e nome derivado. Em seguida aciona “Sair da conta” e verifica Login, perfil padrão restaurado e solicitações vazias.

### Cenário 5 — Alternância de tema

Na Home, registra o brilho inicial, alterna o tema por `AppTheme.toggleTheme`, confirma que `MaterialApp` passa ao brilho oposto e verifica o valor de `themeModeNotifier`. Alterna novamente e confirma o retorno ao brilho inicial.

### Cenário 6 — Botão Voltar e histórico de navegação

Entra na Home, navega de Início para Categorias e depois para Meus Aluguéis. Dois eventos de Voltar restauram Categorias e Início, mantendo `HomeScreen` montada. Em seguida abre Detalhes e verifica que o retorno do sistema fecha Detalhes sem remover a Home.

### Limites da cobertura atual

Não há teste dedicado para unidade semanal, datas iguais ou invertidas, datas com horários diferentes, argumento ausente/inválido, catálogo vazio, observações, estado de erro da imagem, ações de cadastro ou recuperação de senha. O teste compacto cobre busca na Home, não todas as telas nem teclado aberto.

## 8. Diagnóstico Técnico, Limitações e Roadmap

### 8.1 Auditoria técnica

| Área | Evidência do código/testes | Avaliação |
|---|---|---|
| Organização | 16 arquivos Dart organizados em camadas e cinco telas | Estrutura clara para o escopo do MVP. |
| Imports e análise estática | `flutter analyze` sem issues | Aprovado na execução registrada abaixo. |
| Dependências | `material_ui`, `cupertino_icons`; `flutter_test` e `flutter_lints` em desenvolvimento | Nenhum pacote de estado, `intl`, Firebase ou banco declarado. `cupertino_icons` não é referenciado por `CupertinoIcons` nos arquivos Dart analisados e pode ser avaliado para remoção. |
| Navegação | Cinco rotas registradas em `AppRoutes`; argumentos `Product` no fluxo de detalhes e aluguel | Fluxo principal testado; fallback silencioso merece decisão explícita para produção. |
| Ciclo de vida | `dispose()` em Splash, Login, Home e Rental | Controladores e timer observados são liberados; Splash também confere `mounted` antes da navegação. |
| Estado | `UserProfile.currentUser` e `Rental.localRequests` estáticos | Adequado apenas para demonstração; sem persistência e isolamento de sessão. |
| Datas | Normalização para meia-noite e validação de ao menos um dia | Regra implementada; cobertura de datas inválidas ainda ausente. |
| Valores | Tarifas diárias diretas e regra semanal proporcional | Regra semanal existe no código, mas não há produto semanal no catálogo nem teste correspondente. |
| Responsividade | Flex, ellipsis, rolagem, Wrap e layout responsivo de datas | Teste 360×800 da busca passou; não é validação universal de todas as telas. |
| Dados | Oito produtos demonstrativos, todos `por dia` | Sem disponibilidade real, API ou catálogo editável. |
| Aparência e desempenho | `ValueNotifier<ThemeMode>`, temas `static final`, `Duration.zero` | Troca reativa e instantânea entre os dois temas sem reconstruir os objetos `ThemeData`. |
| Navegação de retorno | `_tabHistory`, `_navigateToTab` e `PopScope` em `HomeScreen` | Voltar percorre as abas visitadas e preserva a Home até o último nível. |
| Recursos nativos Android | Ícone adaptativo vetorial, splash e rótulo `AlugaPlay` | Foreground adaptativo XML nítido; PNGs de foreground conflitantes removidos; splash Android 12+ sem ícone duplicado. |
| Assets | Declaração de `assets/images/` e `assets/icons/` no `pubspec.yaml` | Ícone Flutter/launcher e recursos Android acompanham a identidade visual final. |

### 8.2 Melhorias mapeadas

1. **Fallback de produto:** Detalhes e Solicitação substituem argumento nulo ou inválido por `mockProducts.first`. Para evitar inconsistência, uma evolução deve apresentar estado inválido/retorno ao catálogo em vez de criar uma solicitação para item não escolhido.
2. **Cobertura semanal:** a regra divide o preço por sete, porém os oito itens atuais têm cobrança diária. Adicionar um item semanal e testar períodos de um, sete e mais dias permitiria validar a intenção e arredondamento.
3. **Dependência `cupertino_icons`:** está declarada no `pubspec.yaml`; os arquivos Dart lidos não usam `CupertinoIcons`. Confirmar se há uso fora do escopo atual antes de remover.
4. **Validação de e-mail:** `updateFromLoginEmail` transforma a entrada em perfil sem validar formato; isso é coerente com modo demonstrativo, mas insuficiente para autenticação real.
5. **Precisão monetária:** `double` é usado no catálogo e nos totais. Em integração financeira, adotar representação decimal apropriada e regras de arredondamento definidas no domínio/backend.
6. **Separação de estado:** mover lista/perfil para repositórios ou camada de aplicação quando surgir persistência, testes de unidade mais amplos ou sessões concorrentes.
7. **Cobertura de comportamento:** acrescentar testes para argumentos inválidos, calendário, campos opcionais, integração de teclado e acessibilidade.

### 8.3 Saída literal da validação

Formatação: `dart format lib/theme/app_theme.dart lib/app/app.dart lib/screens/splash/splash_screen.dart lib/screens/login/login_screen.dart lib/screens/home/home_screen.dart lib/components/product_card.dart test/widget_test.dart`

Validação: `flutter analyze && flutter test --no-pub`

```text
Analyzing AlugaPlay...
No issues found! (ran in 2.8s)
00:00 +0: loading C:/Users/anton/OneDrive/Documentos/Estudos/FACULDADE/Flutter/AlugaPlay/test/widget_test.dart
00:00 +0: Splash screen navigates to login after its display interval
00:00 +1: customer can rent a selected catalog product end to end
00:02 +2: home search filters products on a compact screen without overflow
00:03 +3: login email appears in profile and sign out returns to login
00:03 +4: user can switch between light and dark themes
00:04 +5: system back follows tab history and pops product details
00:05 +6: All tests passed!
```

O resultado comprova análise estática limpa e aprovação dos seis cenários listados. Não foram executados build Android ou testes em dispositivo nesta validação.

### 8.4 Roadmap para evolução

**Etapa A — Robustez do protótipo**

- Trocar fallbacks silenciosos por tratamento explícito de argumento ausente/inválido.
- Adicionar testes para períodos inválidos, tarifas semanais, limites de datas e dados vazios.
- Definir se uma solicitação cancelada deve ser removida ou manter histórico/status de cancelamento.
- Avaliar remoção de `cupertino_icons` após confirmar o escopo total de uso.

**Etapa B — Persistência local**

- Introduzir repositórios para produtos, perfil e solicitações.
- Persistir dados localmente com versionamento/migração e estados de carregamento/erro.
- Tornar explícita a distinção entre dados em cache e disponibilidade atual.

**Etapa C — Backend e identidade**

- Integrar Firebase Auth ou serviço equivalente para autenticação real.
- Persistir catálogo, usuários e solicitações em Firestore ou API com autorização por usuário.
- Validar períodos, preços e disponibilidade no servidor; a estimativa do cliente não deve ser fonte de verdade.

**Etapa D — Operação comercial**

- Implementar disponibilidade por data, regras de conflito, entrega/devolução e cancelamento.
- Integrar gateway de pagamento com tokenização e processamento seguro; não armazenar dados sensíveis de cartão no app.
- Acrescentar observabilidade, política de privacidade, logs sem dados sensíveis, acessibilidade e testes de integração em dispositivos.
- Automatizar análise, testes e builds por CI antes de publicar.

## Apêndice — Inventário arquivo por arquivo

| Arquivo | Responsabilidade e símbolos principais |
|---|---|
| `lib/main.dart` | Ponto de entrada; função `main()` chama `runApp`. |
| `lib/app/app.dart` | `AlugaPlayApp`; `MaterialApp`, tema, rota inicial e mapa. |
| `lib/theme/app_theme.dart` | `AppTheme`; paletas claro/escuro, `ValueNotifier`, temas cacheados e configuração Material. |
| `lib/routes/app_routes.dart` | `AppRoutes`; cinco constantes e getter `routes`. |
| `lib/models/product.dart` | `Product`; dados imutáveis e getter `formattedPrice`. |
| `lib/models/rental.dart` | `Rental`; dados da locação e lista estática `localRequests`. |
| `lib/models/user_profile.dart` | `UserProfile`; perfil padrão, `currentUser`, `updateFromLoginEmail` e `reset`. |
| `lib/data/mock_products.dart` | Constante `mockProducts` com oito registros e um destaque. |
| `lib/components/primary_button.dart` | `PrimaryButton`; ação padronizada compacta ou regular. |
| `lib/components/category_item.dart` | `CategoryItem`; filtro selecionável e animado. |
| `lib/components/product_card.dart` | `ProductCard`; resumo do produto e callback de detalhes. |
| `lib/screens/splash/splash_screen.dart` | `SplashScreen` e `_SplashScreenState`; animação, timer e ciclo de vida. |
| `lib/screens/login/login_screen.dart` | `LoginScreen` e `_LoginScreenState`; campos, modo demonstrativo e avisos. |
| `lib/screens/home/home_screen.dart` | `HomeScreen` e `_HomeScreenState`; quatro abas, histórico de navegação, catálogo, perfil e aluguéis. |
| `lib/screens/product_details/product_details_screen.dart` | `ProductDetailsScreen`; leitura de argumento e apresentação de produto. |
| `lib/screens/rental/rental_screen.dart` | `RentalScreen` e `_RentalScreenState`; datas, cálculo e confirmação local. |
| `test/widget_test.dart` | Isolamento e seis cenários automatizados de widget, incluindo temas e retorno. |
| `pubspec.yaml` | Nome `alugaplay`, SDK Dart `^3.14.0`, dependências e assets declarados. |

## Equipe e Divisão de Responsabilidades

| Integrante | Responsabilidades |
|---|---|
| Antonio Moura da Costa Filho | Tela Inicial / Catálogo (`HomeScreen`) e Tela de Detalhes do Produto (`ProductDetailsScreen`). |
| Enzo de Melo Cordeiro | Tela de Abertura (`SplashScreen`) e Tela de Acesso (`LoginScreen`). |
| Marcus Vinicius Ferreira Lustosa | Tela de Solicitação de Aluguel (`RentalScreen`). |
