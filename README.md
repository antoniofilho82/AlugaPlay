# AlugaPlay

### Plataforma mobile demonstrativa para explorar consoles, jogos físicos e pacotes gamer

![Flutter](https://img.shields.io/badge/Flutter-mobile-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-%5E3.14.0-0175C2?logo=dart)
![Plataforma](https://img.shields.io/badge/Plataforma-Android-3DDC84?logo=android&logoColor=white)
![Status](https://img.shields.io/badge/Status-MVP%20Fase%201-orange)

## Sobre o Projeto

O AlugaPlay é um protótipo Flutter para explorar e solicitar a locação de consoles, jogos físicos e pacotes de acessórios. O MVP concentra-se em navegação, catálogo local, cadastro e login demonstrativos, perfil, filtros, estimativa de período e histórico local de solicitações.

> **Importante:** a autenticação, o estoque, a reserva e o pagamento são demonstrativos. Contas, perfil, preferências e solicitações são gravados localmente no aparelho por `SharedPreferences`; não há backend, cobrança, verificação KYC externa ou disponibilidade em tempo real.

## Funcionalidades Implementadas

- **Splash Screen:** apresentação da marca por asset local, barra de progresso e espera da restauração local antes do redirecionamento.
- **Acesso demonstrativo:** contas locais com cadastro, login, recuperação de senha e opção de lembrar o acesso.
- **Catálogo interativo (`HomeScreen`):** busca por nome ou plataforma combinada com categoria, console/plataforma e estilo inferido das informações locais.
- **Detalhes do produto (`ProductDetailsScreen`):** informações, especificações técnicas, itens incluídos e tarifa do catálogo local.
- **Solicitação de aluguel (`RentalScreen`):** seleção de datas, modalidade retirada/delivery, endereço, observações, validação de período e estimativa local.
- **Meus Aluguéis:** solicitações persistidas, ordenadas da mais recente para a mais antiga, com cancelamento e limpeza do histórico.
- **Perfil:** edição de dados, CPF com validação local, foto da galeria, preferências e logout.
- **Modo Claro e Modo Escuro:** alternância instantânea com temas centralizados e cacheados em `AppTheme`.
- **Navegação inteligente do botão Voltar:** histórico das abas da Home, retorno por abas visitadas e navegação de volta entre as telas de detalhes e solicitação.
- **Identidade Android:** ícone adaptativo vetorial alinhado ao emblema da SplashScreen e splash nativa configurada para não duplicar a marca no Android 12+.

## Identidade Visual — Paleta Oficial

| Modo | Elemento | Cor |
|---|---|---|
| Escuro | Fundo azul-noturno | `#050811` |
| Escuro | Superfícies | `#0A1224` |
| Escuro | Containers | `#101B36` |
| Escuro | Azul primário / ciano | `#2563EB` / `#38BDF8` |
| Escuro | Amarelo de destaque | `#FACC15` |
| Escuro | Textos claros | `#F8FAFC` |
| Claro | Fundo neutro | `#F8FAFC` |
| Claro | Superfícies brancas | `#FFFFFF` |
| Claro | Containers azulados | `#EFF6FF` |
| Claro | Azul primário | `#1D4ED8` |
| Claro | Amarelo âmbar | `#A16207` |
| Claro | Textos escuros | `#0F172A` / `#334155` |

Os dois temas e os estilos globais são centralizados em `AppTheme`, em `lib/theme/app_theme.dart`. O `ValueNotifier<ThemeMode>` atualiza a aparência em runtime, e `themeAnimationDuration: Duration.zero` aplica a troca sem animação.

## Arquitetura e Estrutura do Projeto

```text
assets/
├── icons/                 # Ícones e recursos visuais do aplicativo
└── images/                # Imagens locais
lib/
├── app/                   # Configuração do MaterialApp
├── components/            # Widgets reutilizáveis
├── data/                  # Catálogo demonstrativo
├── models/                # Modelos Product, Rental e UserProfile
├── routes/                # Constantes e registro das rotas nomeadas
├── screens/               # Splash, Login, Home, Detalhes e Solicitação
├── services/              # Inicialização, autenticação e persistência locais
└── theme/                 # Paleta e tema global
test/
└── widget_test.dart       # Testes de widget das jornadas principais
```

### Jornada de navegação

```text
Splash -> Login -> Home -> Detalhes -> Solicitação -> Confirmação
                      |                               |
                      +-> Categorias                  +-> Meus Aluguéis
                      +-> Meus Aluguéis
                      +-> Perfil -> atalhos / logout
```

As telas principais são registradas por rotas nomeadas em `AppRoutes`. O produto selecionado é encaminhado como argumento de navegação de Home para Detalhes e, em seguida, para Solicitação.

Na Home, a barra inferior e os atalhos registram as abas visitadas. O botão Voltar percorre esse histórico antes de limpar filtros ou deixar a tela; nas rotas de produto, o retorno fecha a tela atual e recupera a Home.

## Como Executar e Testar

Pré-requisitos: Flutter instalado e um emulador Android ou dispositivo disponível.

### Instalar dependências

```bash
flutter pub get
```

### Executar no Android

```bash
flutter run
```

### Análise estática e testes

```bash
flutter analyze && flutter test --no-pub
```

O conjunto atual possui 16 casos: 14 testes de widget e 2 testes unitários.
Ele cobre Splash e restauração, jornada de aluguel, busca e filtros, temas,
histórico de navegação, Perfil, CPF/foto, autenticação local, cadastro e
auto-login. Os detalhes completos estão em
[`Relatorio_Tecnico.md`](./Relatorio_Tecnico.md).

### Gerar APK de demonstração

```bash
flutter build apk --debug
```

## Documentação Técnica e Próximos Passos

A documentação técnica detalhada do código, arquitetura, regras de negócio, testes, limitações e diagnóstico está disponível nos relatórios técnicos da raiz do repositório, incluindo [`Relatorio_Tecnico.md`](./Relatorio_Tecnico.md).

Possíveis evoluções futuras, ainda não implementadas neste repositório:

- Autenticação e catálogo conectados a um backend.
- Controle de disponibilidade e estoque por período.
- Processamento real de pagamento e revisão de políticas de KYC.
- Sincronização remota de perfil e solicitações.
- Medição real de FPS, memória e cold start em dispositivos físicos.

## Equipe de Desenvolvimento

- **Antonio Moura da Costa Filho** — Tela Inicial / Catálogo (`HomeScreen`) e Tela de Detalhes do Produto (`ProductDetailsScreen`).
- **Enzo de Melo Cordeiro** — Tela de Abertura (`SplashScreen`) e Tela de Acesso (`LoginScreen`).
- **Marcus Vinicius Ferreira Lustosa** — Tela de Solicitação de Aluguel (`RentalScreen`).
## Configurações e experiência de locação

Na aba **Perfil**, o jogador pode editar nome, telefone/WhatsApp e cidade, além de
definir modalidade padrão (retirada ou delivery), duração (1, 3 ou 7 dias) e
plataforma favorita. As preferências de aparência oferecem os modos Sistema,
Claro e Escuro; também é possível configurar lembretes de devolução e novidades
do catálogo. Esses dados são persistidos localmente por `SharedPreferences`.

Na Home, categoria, busca, console/plataforma e estilo podem ser combinados.
No fluxo de locação, o usuário escolhe datas e modalidade, com validação mínima
de um dia. Não há cobrança real nem confirmação de estoque externa.

## Autenticação local

O acesso exige uma conta criada no próprio aplicativo: cadastro, login e
recuperação de senha são mantidos localmente. A opção **Lembrar meu acesso**
guarda o e-mail e a preferência da sessão, mas nunca pré-preenche a senha.
Desmarcá-la impede o auto-login. A tela **Criar Nova Conta** valida os dados e
autentica após o cadastro. Em **Recuperar Senha**, o e-mail é verificado
localmente antes de permitir redefinir a senha.

## Endereço de entrega

O cadastro rápido solicita somente nome, e-mail, telefone/WhatsApp e senha.
Cidade e endereço são opcionais e podem ser adicionados em Perfil. A tela de
locação preenche o endereço salvo quando a modalidade selecionada é Delivery;
sem endereço cadastrado, o campo fica disponível para preenchimento no pedido.

