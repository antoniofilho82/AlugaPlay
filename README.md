# AlugaPlay

### Plataforma mobile para locação de consoles, jogos físicos e pacotes gamer

![Flutter](https://img.shields.io/badge/Flutter-mobile-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-%5E3.14.0-0175C2?logo=dart)
![Plataforma](https://img.shields.io/badge/Plataforma-Android-3DDC84?logo=android&logoColor=white)
![Status](https://img.shields.io/badge/Status-MVP%20Fase%201-orange)

## Sobre o Projeto

O AlugaPlay é um protótipo de uma plataforma para explorar e solicitar a locação de consoles, jogos físicos e pacotes de acessórios. A proposta é oferecer uma forma flexível de experimentar produtos gamer sem o custo de aquisição definitiva.

O público-alvo são jogadores interessados em testar diferentes plataformas e pessoas que procuram conjuntos prontos para jogar. O MVP da Fase 1 concentra-se no front-end mobile: apresenta catálogo, detalhes dos produtos, escolha de período, estimativa de valor e acompanhamento das solicitações.

> **Importante:** este é um protótipo demonstrativo. O catálogo, o perfil e as solicitações são mantidos em memória; não há autenticação real, disponibilidade de estoque, reserva persistente ou pagamento.

## Funcionalidades Implementadas

- **Splash Screen animada:** entrada da marca com fade e escala usando `AnimationController`, seguida de redirecionamento automático para o login.
- **Acesso demonstrativo:** login com alternância da visibilidade da senha; o e-mail informado gera um nome de exibição e uma `@gamertag` para o perfil da sessão.
- **Catálogo interativo (`HomeScreen`):** busca em tempo real por nome ou plataforma combinada com filtros `Todos`, `Consoles`, `Jogos` e `Pacotes`, além de destaque semanal e seção de pacotes especiais.
- **Detalhes do produto (`ProductDetailsScreen`):** informações e especificações técnicas, itens incluídos, indicação de disponibilidade demonstrativa e tarifa.
- **Solicitação de aluguel (`RentalScreen`):** seleção de retirada e devolução, validação do período mínimo de um dia, estimativa para tarifa diária ou semanal proporcional, observações e confirmação local.
- **Meus Aluguéis:** solicitações da sessão em ordem da mais recente para a mais antiga, com resumo e opção de cancelamento.
- **Perfil:** dados da conta demonstrativa, contagem de solicitações, atalhos de navegação e ação para sair da conta.

## Identidade Visual — Paleta Gamer Oficial

| Cor | Aplicação |
|---|---|
| `#101814` | Fundo principal |
| `#1C2922` | Superfícies, cards e barra de navegação |
| `#16A34A` | Ações primárias e estados selecionados |
| `#4ADE80` | Destaques, ícones e valores estimados |
| `#F0FDF4` | Tipografia principal de alto contraste |

O tema escuro e os estilos globais são centralizados em `AppTheme`, em `lib/theme/app_theme.dart`.

## Arquitetura e Estrutura do Projeto

```text
assets/
├── icons/                 # Ícones e recursos visuais do aplicativo
└── images/                # Imagens locais
lib/
├── app/                   # Configuração da aplicação Flutter
├── components/            # Widgets reutilizáveis
├── data/                  # Catálogo demonstrativo
├── models/                # Modelos Product, Rental e UserProfile
├── routes/                # Constantes e registro das rotas nomeadas
├── screens/               # Splash, Login, Home, Detalhes e Solicitação
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

Os quatro testes de widget cobrem:

1. Redirecionamento da Splash para Login.
2. Jornada de aluguel completa, registro da solicitação e cancelamento.
3. Busca na Home em viewport compacto de `360x800`.
4. Exibição do e-mail no Perfil e logout para a tela de Login.

### Gerar APK de demonstração

```bash
flutter build apk --debug
```

## Documentação Técnica e Próximos Passos

A documentação técnica detalhada do código, arquitetura, regras de negócio, testes, limitações e diagnóstico está disponível nos relatórios técnicos da raiz do repositório, incluindo [`Relatorio_Tecnico.md`](./Relatorio_Tecnico.md).

Evoluções planejadas para as próximas fases:

- Persistência local de perfil e solicitações.
- Autenticação real com Firebase Auth.
- Catálogo dinâmico e dados em nuvem, por exemplo com Firestore.
- Controle de disponibilidade por período.
- Integração com gateway de pagamento.

## Equipe de Desenvolvimento

- **Antonio Moura da Costa Filho**
- **Enzo de Melo Cordeiro**
- **Marcus Vinicius Ferreira Lustosa**
