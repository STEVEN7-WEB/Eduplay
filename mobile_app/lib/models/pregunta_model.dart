class Pregunta {
  final String enunciado;
  final List<String> opciones;
  final int respuestaCorrecta;
  final int gradoMinimo;

  Pregunta({
    required this.enunciado,
    required this.opciones,
    required this.respuestaCorrecta,
    required this.gradoMinimo,
  });
}

// Ejemplo de base de datos local temporal
List<Pregunta> bancoMatematicas = [
  Pregunta(enunciado: "2 + 2 = ?", opciones: ["3", "4", "5"], respuestaCorrecta: 1, gradoMinimo: 1),
  Pregunta(enunciado: "10 - 4 = ?", opciones: ["6", "7", "5"], respuestaCorrecta: 0, gradoMinimo: 1),
  Pregunta(enunciado: "5 x 4 = ?", opciones: ["20", "25", "15"], respuestaCorrecta: 0, gradoMinimo: 2),
  Pregunta(enunciado: "100 / 4 = ?", opciones: ["20", "25", "30"], respuestaCorrecta: 1, gradoMinimo: 3),
  Pregunta(enunciado: "¿Cuál es el área de un cuadrado de lado 5?", opciones: ["10", "20", "25"], respuestaCorrecta: 2, gradoMinimo: 4),
  Pregunta(enunciado: "Raíz cuadrada de 64", opciones: ["6", "8", "12"], respuestaCorrecta: 1, gradoMinimo: 5),
];

List<Pregunta> bancoEspanol = [
  Pregunta(enunciado: "¿Qué palabra es un verbo?", opciones: ["Perro", "Correr", "Bonito"], respuestaCorrecta: 1, gradoMinimo: 1),
  Pregunta(enunciado: "Sinónimo de Feliz", opciones: ["Triste", "Enojado", "Alegre"], respuestaCorrecta: 2, gradoMinimo: 2),
];
// Agrega más bancos para Ciencias y Geografía...