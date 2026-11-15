import 'package:material_ui/material_ui.dart';

import '../models/product.dart';

// O catálogo fixo deixa a navegação e os cálculos disponíveis sem serviço externo.
// Os itens cobrem consoles, jogos físicos e pacotes para exercitar os filtros.
const List<Product> mockProducts = [
  // Consoles individuais.
  Product(
    id: 'ps5-disc',
    name: 'PlayStation 5 com Leitor',
    category: 'Consoles',
    platform: 'PlayStation 5',
    shortDescription: 'Experimente jogos em alta definição e resposta rápida.',
    fullDescription:
        'Console PlayStation 5 com leitor de discos, pronto para sessões '
        'imersivas e jogos físicos.',
    rentalPrice: 89.90,
    billingUnit: 'por dia',
    icon: Icons.sports_esports_rounded,
    specs: ['SSD ultrarrápido', 'Saída 4K', 'Leitor de Blu-ray'],
    includedItems: [
      'Console PS5',
      'Controle DualSense',
      'Cabos de energia e HDMI',
    ],
    demoAvailabilityLabel: 'Disponível para solicitação demonstrativa',
  ),
  Product(
    id: 'xbox-series-x',
    name: 'Xbox Series X',
    category: 'Consoles',
    platform: 'Xbox Series X',
    shortDescription: 'Desempenho de nova geração para jogar em 4K.',
    fullDescription:
        'Console Xbox Series X para aproveitar uma ampla seleção de jogos '
        'em uma experiência de alto desempenho.',
    rentalPrice: 84.90,
    billingUnit: 'por dia',
    icon: Icons.gamepad_rounded,
    specs: ['Armazenamento SSD', 'Saída 4K', 'Compatível com jogos Xbox'],
    includedItems: [
      'Console Xbox Series X',
      'Controle sem fio',
      'Cabos de energia e HDMI',
    ],
    demoAvailabilityLabel: 'Disponível para solicitação demonstrativa',
  ),
  Product(
    id: 'switch-oled',
    name: 'Nintendo Switch OLED',
    category: 'Consoles',
    platform: 'Nintendo Switch',
    shortDescription: 'Jogue no modo portátil ou conectado à TV.',
    fullDescription:
        'Nintendo Switch OLED versátil para jogar em casa ou levar suas '
        'partidas para onde quiser.',
    rentalPrice: 59.90,
    billingUnit: 'por dia',
    icon: Icons.videogame_asset_rounded,
    specs: [
      'Tela OLED de 7 polegadas',
      'Modo portátil e TV',
      'Armazenamento interno',
    ],
    includedItems: ['Console Nintendo Switch OLED', 'Joy-Con', 'Dock e cabos'],
    demoAvailabilityLabel: 'Disponível para solicitação demonstrativa',
  ),
  // Jogos em mídia física para diferentes plataformas.
  Product(
    id: 'spider-man-2',
    name: "Marvel's Spider-Man 2",
    category: 'Jogos',
    platform: 'PlayStation 5',
    shortDescription: 'Aventura de ação física para PS5.',
    fullDescription:
        'Jogo físico de ação e aventura ambientado no universo do Homem-Aranha, '
        'para PlayStation 5.',
    rentalPrice: 24.90,
    billingUnit: 'por dia',
    icon: Icons.auto_awesome_rounded,
    specs: ['Mídia física', 'Aventura para um jogador', 'Compatível com PS5'],
    includedItems: ['Disco do jogo', 'Estojo original'],
    demoAvailabilityLabel: 'Disponível para solicitação demonstrativa',
  ),
  Product(
    id: 'zelda-totk',
    name: 'The Legend of Zelda: Tears of the Kingdom',
    category: 'Jogos',
    platform: 'Nintendo Switch',
    shortDescription: 'Aventura física para explorar Hyrule.',
    fullDescription:
        'Jogo físico de aventura para Nintendo Switch, com exploração e desafios '
        'em um vasto mundo.',
    rentalPrice: 19.90,
    billingUnit: 'por dia',
    icon: Icons.explore_rounded,
    specs: [
      'Mídia física',
      'Aventura para um jogador',
      'Compatível com Switch',
    ],
    includedItems: ['Cartucho do jogo', 'Estojo original'],
    demoAvailabilityLabel: 'Disponível para solicitação demonstrativa',
  ),
  // Pacotes combinam consoles e acessórios para cenários de uso variados.
  Product(
    id: 'ps5-extra-dualsense',
    name: 'Pacote PS5 + Controle DualSense Extra',
    category: 'Pacotes',
    platform: 'PlayStation 5',
    shortDescription: 'Console e controle adicional para jogar em dupla.',
    fullDescription:
        'Pacote demonstrativo com PlayStation 5 e um controle DualSense extra '
        'para partidas locais.',
    rentalPrice: 109.90,
    billingUnit: 'por dia',
    icon: Icons.group_rounded,
    specs: ['Console PS5 com leitor', 'Dois controles sem fio', 'Saída 4K'],
    includedItems: [
      'Console PS5',
      '2 controles DualSense',
      'Cabos de energia e HDMI',
    ],
    demoAvailabilityLabel: 'Disponível para solicitação demonstrativa',
  ),
  Product(
    id: 'xbox-games-pack',
    name: 'Pacote Xbox Series X + 2 Jogos Físicos',
    category: 'Pacotes',
    platform: 'Xbox Series X',
    shortDescription: 'Console acompanhado de dois jogos físicos selecionados.',
    fullDescription:
        'Pacote demonstrativo com Xbox Series X e dois jogos físicos para '
        'começar a jogar assim que receber o conjunto.',
    rentalPrice: 119.90,
    billingUnit: 'por dia',
    icon: Icons.stars_rounded,
    specs: ['Console Xbox Series X', 'Dois jogos físicos', 'Controle sem fio'],
    includedItems: [
      'Console Xbox Series X',
      'Controle sem fio',
      '2 jogos físicos',
      'Cabos',
    ],
    demoAvailabilityLabel: 'Disponível para solicitação demonstrativa',
    isFeatured: true,
  ),
  Product(
    id: 'switch-multiplayer-pack',
    name: 'Pacote Nintendo Switch OLED + Kit Multiplayer e Case',
    category: 'Pacotes',
    platform: 'Nintendo Switch',
    shortDescription:
        'Console, acessórios multiplayer e proteção para transporte.',
    fullDescription:
        'Pacote demonstrativo com Nintendo Switch OLED, acessórios para jogar '
        'em grupo e case para transporte.',
    rentalPrice: 94.90,
    billingUnit: 'por dia',
    icon: Icons.sports_esports_rounded,
    specs: [
      'Console Switch OLED',
      'Acessórios multiplayer',
      'Case de transporte',
    ],
    includedItems: [
      'Console Nintendo Switch OLED',
      'Joy-Con',
      'Kit multiplayer',
      'Case',
    ],
    demoAvailabilityLabel: 'Disponível para solicitação demonstrativa',
  ),
];
