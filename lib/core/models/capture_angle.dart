/// Fotoğraf çekim açıları
enum CaptureAngle {
  frontFace(
    'Ön Yüz',
    'Lütfen yüzünüzü tam karşıdan iyi bir ışık alacak şekilde fotoğraf çekimini yapınız.',
    1,
  ),
  leftSide(
    'Sol Taraf',
    'Lütfen yüzünüzün sol tarafını tam karşıdan alacak şekilde fotoğraf çekimini yapınız.',
    2,
  ),
  rightSide(
    'Sağ Taraf',
    'Lütfen yüzünüzün sağ tarafını tam karşıdan alacak şekilde fotoğraf çekimini yapınız.',
    3,
  ),
  topVertex(
    'Üst Taraf',
    'Lütfen kafanızın tam olarak üst kısmı görünecek şekilde fotoğraf çekimini yapınız.',
    4,
  ),
  backDonor(
    'Arka Taraf',
    'Lütfen kafanızın arka kısmının doğru ışık altında fotoğraf çekimini yapınız.',
    5,
  );

  final String name;
  final String instruction;
  final int stepNumber;
  const CaptureAngle(this.name, this.instruction, this.stepNumber);
}

