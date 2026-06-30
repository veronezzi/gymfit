/// Traduções para português dos rótulos do dataset (em inglês).
library;

const Map<String, String> categoryLabelsPt = {
  'back': 'Costas',
  'cardio': 'Cardio',
  'chest': 'Peito',
  'lower arms': 'Antebraços',
  'lower legs': 'Panturrilhas',
  'neck': 'Pescoço',
  'shoulders': 'Ombros',
  'upper arms': 'Braços',
  'upper legs': 'Pernas',
  'waist': 'Abdômen',
};

const Map<String, String> targetLabelsPt = {
  'abductors': 'Abdutores',
  'abs': 'Abdominais',
  'adductors': 'Adutores',
  'biceps': 'Bíceps',
  'calves': 'Panturrilhas',
  'cardiovascular system': 'Sistema cardiovascular',
  'delts': 'Deltoides',
  'forearms': 'Antebraços',
  'glutes': 'Glúteos',
  'hamstrings': 'Posteriores de coxa',
  'lats': 'Dorsais',
  'levator scapulae': 'Levantador da escápula',
  'pectorals': 'Peitorais',
  'quads': 'Quadríceps',
  'serratus anterior': 'Serrátil anterior',
  'spine': 'Coluna',
  'traps': 'Trapézio',
  'upper back': 'Costas (superior)',
};

const Map<String, String> equipmentLabelsPt = {
  'assisted': 'Assistido',
  'band': 'Faixa elástica',
  'barbell': 'Barra',
  'body weight': 'Peso corporal',
  'bosu ball': 'Bola Bosu',
  'cable': 'Polia',
  'dumbbell': 'Halteres',
  'elliptical machine': 'Elíptico',
  'ez barbell': 'Barra W',
  'hammer': 'Martelo',
  'kettlebell': 'Kettlebell',
  'leverage machine': 'Máquina',
  'medicine ball': 'Bola medicinal',
  'olympic barbell': 'Barra olímpica',
  'resistance band': 'Faixa de resistência',
  'roller': 'Rolo',
  'rope': 'Corda',
  'skierg machine': 'Máquina SkiErg',
  'sled machine': 'Máquina de trenó',
  'smith machine': 'Smith machine',
  'stability ball': 'Bola de estabilidade',
  'stationary bike': 'Bicicleta ergométrica',
  'stepmill machine': 'Escada (stepmill)',
  'tire': 'Pneu',
  'trap bar': 'Barra hexagonal',
  'upper body ergometer': 'Ergômetro de braços',
  'weighted': 'Com peso',
  'wheel roller': 'Roda abdominal',
};

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Capitaliza apenas a primeira letra (sentence case) — adequado a PT e EN.
String sentenceCase(String s) => _capitalize(s);

String categoryPt(String key) => categoryLabelsPt[key] ?? _capitalize(key);
String targetPt(String key) => targetLabelsPt[key] ?? _capitalize(key);
String equipmentPt(String key) => equipmentLabelsPt[key] ?? _capitalize(key);

/// Ícone representativo por grupo muscular (usa Material Icons).
