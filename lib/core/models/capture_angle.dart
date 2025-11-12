/// Fotoğraf çekim açıları
enum CaptureAngle {
  frontFace('Ön Yüz', 'Kameraya doğrudan bakın', 1),
  leftSide('Sol Yüz', 'Kafanızı sola çevirin', 2),
  rightSide('Sağ Yüz', 'Kafanızı sağa çevirin', 3),
  topVertex('Tepe (Vertex)', 'Telefonu kafanızın üstüne kaldırın', 4),
  backDonor('Arka Donör', 'Telefonu kafanızın arkasına alın', 5);

  final String name;
  final String instruction;
  final int stepNumber;
  const CaptureAngle(this.name, this.instruction, this.stepNumber);
}

