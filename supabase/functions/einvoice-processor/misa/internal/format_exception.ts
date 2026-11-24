/** Port of Dart `FormatException`: toString() is `FormatException: <message>`. */
export class FormatException extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'FormatException'
  }
}
