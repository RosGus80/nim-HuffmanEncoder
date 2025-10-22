import src

proc main() =
    var input_text: string
    echo "Введите текст, который хотите закодировать (не вводите текст с разделением строк - консоль думает, что вы закончили писать): "
    input_text = readline(stdin)

    let huff = new_huffman_encoder(input_text)

    let encoded_string: string = huff.encode_message()

    echo "Закодированный текст: " & encoded_string

    let decoded_string: string = huff.decode_message(encoded_string)

    if decoded_string == input_text:
        echo "Декодированный текст (выводит то же, что вы и ввели. Значит, все работает хорошо!): " & decoded_string
    else:
        echo "Судя по всему, кодировщик не смог однозначно декодировать обратно в текст :( \n" & decoded_string
        
when isMainModule:
    main()