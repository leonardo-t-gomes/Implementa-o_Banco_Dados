# Aula 07 - 11/09/2026

````sql
-- CRIANDO UMA FUNÇÃO ESCALAR 
CREATE OR ALTER FUNCTION fn_dobro (@Numero DECIMAL (10,2))
RETURNS DECIMAL (10,2)
AS
BEGIN
	RETURN @Numero * 2
END
GO;

SELECT dbo.fn_dobro(250);

-- DOBRO DO SALÁRIO DA MARIA 
SELECT
	Pnome,
	Unome,
	F.Salario,
	dbo.fn_dobro(F.Salario) AS 'Dobro'
FROM FUNCIONARIO AS F
WHERE F.Pnome = 'Maria';

-- DOBRO DO SALÁRIO DE TODOS OS FUNCIONÁRIOS
SELECT
	Pnome,
	Unome,
	F.Salario,
	dbo.fn_dobro(F.Salario) AS 'Dobro'
FROM FUNCIONARIO AS F;

-- ENOCNTRANDO QUEM RECEBE MAIS QUE O DOBRO DO SALÁRIO DE QUEM MENOS RECEBE 
DECLARE @menor_salario DECIMAL (10,2)
SELECT @menor_salario = MIN (Salario)
FROM FUNCIONARIO
SELECT 
	Pnome,
	Unome,
	F.Salario
FROM FUNCIONARIO AS F
WHERE F.Salario > dbo.fn_dobro (@menor_salario);
GO

-- ENCONTRANDO A IDADE DOS FUNCIONÁRIOS NO BANCO
CREATE FUNCTION fn_calcula_idade(@data_nasc DATE)
RETURNS INT 
AS
BEGIN
	DECLARE @idade INT;
	SET @idade = DATEDIFF(YEAR, @data_nasc, GETDATE())
	IF(MONTH(@data_nasc) > MONTH (GETDATE()))
		OR (MONTH(@data_nasc) = MONTH (GETDATE()) AND
			DAY(@data_nasc) > DAY (GETDATE()))
		SET @idade = @idade - 1;
	RETURN @idade;
END;
GO

--IDADE DOS DEPENDENTES 
SELECT 
	D.Nome_dependente,
	CONVERT (VARCHAR, D.Datanasc, 103) AS 'DATA',
	dbo.fn_calcula_idade(D.Datanasc) AS 'IDADE'
FROM DEPENDENTE AS D;

--IDADE DOS FUNCIONÁRIOS
SELECT 
	F.Pnome,
	CONVERT (VARCHAR, F.Datanasc, 103) AS 'DATA NASC',
	dbo.fn_calcula_idade(F.Datanasc) AS 'IDADE'
FROM FUNCIONARIO AS F;
GO

-- FUNÇÃO INLINE: retornando todos os funcionários de um determinado departamento
CREATE FUNCTION fn_funcionario_dpt(@nome_dpt VARCHAR(50))
RETURNS TABLE
AS
RETURN
(
	SELECT 
		F.Pnome,
		F.Unome
	FROM FUNCIONARIO AS F 
	JOIN DEPARTAMENTO AS D
	ON F.Dnr = D.Dnumero
	WHERE D.Dnome = @nome_dpt
);
GO;

SELECT * FROM dbo.fn_funcionario_dpt('Pesquisa');
GO;

-- FUNÇÕES MULTI-STATEMENT: criar uma função que retorna nome completo dos funcionários e o valor anual, com férias e décimo terceiro
CREATE FUNCTION fn_salarioAnual()
RETURNS @salAno TABLE
(
	nome_comp VARCHAR (100),
	salario DECIMAL (10,2),
	salario_anual DECIMAL (10,2)
)
AS 
BEGIN 
	INSERT INTO @salAno
	SELECT 
		CONCAT(F.Pnome, ' ', F.Minicial, ' ', F.Unome),
		f.Salario,
		f.Salario * 13 + (f.Salario * 0.3)
	FROM FUNCIONARIO AS F;
	RETURN;
END
GO

SELECT * FROM dbo.fn_salarioAnual();
GO

-- STORED PROCEDURE
CREATE PROCEDURE sp_exibe_meu_nome
AS 
BEGIN
	PRINT 'Leonardo Teixeira Gomes';
END
GO

EXEC sp_exibe_meu_nome;
GO

--FAZENDO O AUMENTO DO SÁLARIO DOS FUNCIONARIOS
CREATE OR ALTER PROCEDURE sp_aumento(
@porcentagem DECIMAL(3,1),
@cpf CHAR (11)
)
AS 
BEGIN
	UPDATE FUNCIONARIO
	SET Salario = Salario * (1+(@porcentagem/100))
	WHERE  cpf = @cpf
END;
GO

EXEC dbo.sp_aumento @porcentagem = 5, @cpf = '98765432300';
SELECT * FROM FUNCIONARIO;
	
SELECT COUNT(*) FROM FUNCIONARIO

EXEC sp_help sp_aumento;
GO

-- PROCEDURE CRIPTROGRAFADO 
CREATE PROCEDURE sp_funcionarios
WITH ENCRYPTION 
AS
SELECT * FROM FUNCIONARIO;
GO
EXEC sp_help sp_fuuncionarios;
GO

-- PROCEDURE QUE INSERE UM NOVO DEPARTAMENTO NO BANCO COM SUA RESPECTIVA LOCALIDADE
CREATE OR ALTER PROCEDURE sp_add_dpt_loc (
	@dpt_nome VARCHAR (50),
	@dpt_numero INT,
	@local VARCHAR (50))
AS
BEGIN 
	IF EXISTS ( SELECT 1 FROM DEPARTAMENTO
				WHERE Dnome = @dpt_nome)
		BEGIN 
			PRINT 'JÁ EXISTO:   ' + @dpt_nome;
			RETURN;
		END
	ELSE 
		BEGIN 
			INSERT INTO DEPARTAMENTO (Dnome, Dnumero)
			VALUES (@dpt_nome, @dpt_numero);

			INSERT INTO LOCALIZACAO_DEP (Dnumero, Dlocal)
			VALUES (@dpt_numero, @local);
			PRINT 'DEPARTAMENTO INSERIDO:  ' + @dpt_nome;
			PRINT 'LOCAL INSERIDO:  ' + @local;
		END 
END
GO

-- OUTRO MODO DE FAZER
CREATE PROCEDURE sp_dptLocalidade
    @Departamento VARCHAR(50),
    @Localidade VARCHAR(100)
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM DEPARTAMENTO
        WHERE Dnome = @Departamento
    )
    BEGIN
        PRINT 'O departamento já existe com o nome ' +@Departamento;
        RETURN;
END

    ELSE
    BEGIN
        DECLARE @id_dpt INT, @id_loc INT;
        SELECT @id_dpt = MAX(Dnumero)
        FROM DEPARTAMENTO;

        INSERT INTO DEPARTAMENTO (Dnumero, Dnome)
        VALUES (@id_dpt + 1, @Departamento);

        INSERT INTO LOCALIZACAO_DEP (Dnumero, Dlocal)
        VALUES (@id_dpt + 1, @Localidade);

        PRINT @Departamento + 'inserido com sucesso';
        PRINT @Localidade + 'inserido com sucesso';
    END
END
GO

EXEC sp_add_dpt_loc 'COMPRAS', 130, 'SANTA MARIA';

SELECT *
FROM DEPARTAMENTO AS D
JOIN LOCALIZACAO_DEP AS L
ON D.Dnumero = L.Dnumero;
```

# Aula 06 - 04/09/2026
```sql
-- CAST 
CAST(VALOR AS TIPONOVO);
CAST(@VAR AS VARCHAR(100));

GO;
DECLARE @nome VARCHAR(100),
		@Salario DECIMAL(10,2);
SET @nome = 'Jennifer';

SELECT @Salario = Salario
FROM FUNCIONARIO
WHERE Pnome = @nome;

PRINT 'O funcionario ' + @nome + ' possui o salário de: ' + CAST(@Salario AS VARCHAR(10));
GO;

-- CONVERT
DECLARE @dataNascimento DATE;

SELECT @dataNascimento = dataNasc
FROM FUNCIONARIO
WHERE Pnome = 'Jennifer';

SELECT CONVERT(VARCHAR(10), @dataNascimento, 103) AS DataNascimentoFrances;

-- CONDIÇÃO IF/ELSE

GO;
DECLARE @nome VARCHAR(100),
		@salarioNome DECIMAL(10,2),
		@salario_medio DECIMAL(10,2);

SET @nome = 'Jennifer';

SELECT @salario_medio = AVG(Salario)
FROM FUNCIONARIO;

SELECT @salarioNome = Salario 
FROM FUNCIONARIO
WHERE Pnome = @nome;

IF (@salario_medio > @salarioNome)
	BEGIN 
	PRINT 'Salário médio ('+ CAST(@salario_medio AS VARCHAR(20)) +') maior que o salário de ' + @nome +' (' + CAST(@salarioNome AS VARCHAR(20)) +')';
	END
ELSE 
	BEGIN
	PRINT 'Salário médio ('+ CAST(@salario_medio AS VARCHAR(20))+') menor ou igual ao salário de ' + @nome+' (' + CAST(@salarioNome AS VARCHAR(20)) +')';
	END
GO;

-- SEGUNDA CONSULTA IF/ELSE

GO;
-- Declaração de variáveis
DECLARE @dataNascimento DATE,
        @pNome VARCHAR(100),
        @idade INT;

-- Escolha do nome para buscar na variável
SET @pNome = 'Maria';

-- Busca e salva a data de nascimento com o nome da variável
SELECT @dataNascimento = dataNasc
FROM FUNCIONARIO
WHERE Pnome = @pNome;

-- Define a idade como a diferença da data atual - data de nascimento
SET @idade = DATEDIFF(YEAR, @dataNascimento, GETDATE());

-- Somando a data de nascimento com a idade, se essa data der maior que a de hoje, desconta -1, porque ainda não fez aniversário
IF DATEADD(YEAR, @idade, @dataNascimento) > GETDATE()
BEGIN
    SET @idade = @idade - 1;
END

IF @idade > 60
BEGIN
    PRINT 'Aposentado(a)';
    PRINT 'Idade: ' + CAST(@idade AS VARCHAR(3));
END

ELSE
BEGIN
    PRINT 'Não aposentado(a)';
    PRINT 'Idade: ' + CAST(@idade AS VARCHAR(3));
END
GO;

-- IIF()
SELECT 
	F.Pnome,
	F.Unome,
	F.Salario,
	IIF(F.Salario < 20000, 'Baixo', 'Alto')
FROM FUNCIONARIO AS F;

-- CASE
SELECT 
	F.Pnome,
	F.Unome,
	F.Salario,
	CASE
		WHEN F.Salario <= 10000 AND F.Salario > 0 THEN 'Baixo'
		WHEN F.Salario > 10000 AND F.Salario <= 25000 THEN 'Médio'
		WHEN F.Salario > 25000 THEN 'Alto'
		ELSE 'ERRO'
	END AS 'Categoria'
FROM FUNCIONARIO AS F;

-- LOOP WHILE()
DECLARE @contador INT = 0;

WHILE @contador < 10
BEGIN
	IF @contador % 2 != 0
	BREAK;
	SET @contador = @contador + 1
	PRINT 'Contador: ' + CAST(@contador AS VARCHAR(3));
END

-- CURSORES
DECLARE @nome VARCHAR(50);

DECLARE cursorFuncionario CURSOR FOR
SELECT Pnome FROM FUNCIONARIO;

OPEN cursorFuncionario;

FETCH NEXT FROM cursorFuncionario INTO @nome;
```


# Aula 05 - 28/08/2026
- Comandos estudados em aula
  
```sql
use EMPRESA;

-- UNION
SELECT P.Projlocal AS 'Local'
FROM PROJETO AS P

UNION

SELECT L.Dlocal AS 'Local'
FROM LOCALIZACAO_DEP AS L;

-- EXCEPT
SELECT F.Cpf, F.Pnome
FROM FUNCIONARIO AS F

EXCEPT

SELECT D.Cpf_gerente, F.Pnome
FROM DEPARTAMENTO AS D

JOIN FUNCIONARIO AS F
ON D.Cpf_gerente = F.Cpf

-- INTERSECT
SELECT Cpf
FROM FUNCIONARIO

INTERSECT

SELECT Cpf_supervisor
FROM FUNCIONARIO

-- GROUP BY
SELECT COUNT(F.Cpf) AS 'Qtd_Cpf', F.Sexo
FROM FUNCIONARIO AS F
GROUP BY F.Sexo;

-- ///
SELECT COUNT(F.Cpf) AS 'Qtd_Cpf', D.Dnome
FROM FUNCIONARIO AS F

JOIN DEPARTAMENTO AS D
ON F.Dnr = D.Dnumero

GROUP BY D.Dnome;

-- ///
SELECT SUM(F.Salario) AS 'Soma Salario', D.Dnome
FROM FUNCIONARIO AS F

JOIN DEPARTAMENTO AS D
ON F.Dnr = D.Dnumero

GROUP BY D.Dnome;

-- ///
SELECT AVG(T.Horas) AS 'M Hrs', P.Projnome
FROM TRABALHA_EM AS T

JOIN PROJETO AS P
ON T.Pnr = P.Projnumero

GROUP BY P.Projnome

-- ///
SELECT MAX(F.Salario) AS 'Salario', D.Dnome
FROM FUNCIONARIO AS F

JOIN DEPARTAMENTO AS D
ON F.Dnr = D.Dnumero

GROUP BY D.Dnome

-- HAVING
SELECT COUNT(F.Cpf) AS 'Func', D.Dnome
FROM FUNCIONARIO AS F

JOIN DEPARTAMENTO AS D
ON F.Dnr = D.Dnumero

GROUP BY D.Dnome
HAVING COUNT(F.Cpf) > 3;

-- ///
SELECT SUM(T.Horas) AS 'Min Hrs', P.Projnome
FROM TRABALHA_EM AS T

JOIN PROJETO AS P
ON T.Pnr = P.Projnumero

GROUP BY P.Projnome
HAVING SUM(T.Horas) >= 50;

-- EXISTS
SELECT *
FROM DEPARTAMENTO AS D
WHERE EXISTS (
	SELECT 1
	FROM PROJETO, DEPARTAMENTO
	WHERE PROJETO.Dnum = DEPARTAMENTO.Dnumero
);

-- ANY
SELECT F.Salario
FROM FUNCIONARIO AS F

JOIN DEPARTAMENTO AS D
ON F.Dnr = D.Dnumero

WHERE D.Dnome = 'Administração';

--///
SELECT Pnome, Salario
FROM FUNCIONARIO
WHERE Salario <> ANY (
	SELECT F.Salario
	FROM FUNCIONARIO AS F
	JOIN DEPARTAMENTO AS D
	ON F.Dnr = D.DnumerO
	WHERE D.Dnome = 'Administração'
)
```
- Comandos estudados(Parecido com programação)
```sql
--DECLARE
DECLARE --@nome VARCHAR(100),
		@idade INT,
		--@salario DECIMAL(10,2),
		@data DATE;
SET @nome = 'Herysson R. Figueiredo';
SET @idade = 38;
SET @salario = 2400.00;
SET @data = GETDATE();
PRINT 'OLÁ PUTÃO, TEU NOME É: ' + @nome 
	+ ', Idade: ' + CAST(@idade AS VARCHAR(10));
SELECT
	@nome AS 'Nome',
	@idade AS 'Idade',
	@salario AS 'Grana',
	@data AS 'Data de hoje';

-- ///
DECLARE @nomeDpt VARCHAR(20);

SELECT @nomeDpt = Dnome
FROM DEPARTAMENTO AS D
WHERE D.Dnumero = 4

PRINT 'Departamento' + @nomeDpt;

--- /// 
DECLARE @salario DECIMAL(10,2),
		@novo_salario DECIMAL(10,2),
		@nome VARCHAR(100);
SET @nome = 'Jennifer';
SELECT @salario = F.Salario
FROM FUNCIONARIO AS F
WHERE F.Pnome = @nome;
SET @novo_salario = @salario * 1.1;
PRINT 'Salario: ' + CAST(@salario AS VARCHAR(10))
PRINT 'Novo Salario: ' + CAST(@novo_salario AS VARCHAR(10))

-- ///
DECLARE @dataJennifer DATE

SELECT @dataJennifer = Datanasc
FROM FUNCIONARIO
WHERE Pnome = 'Jennifer'

PRINT DATEDIFF(YEAR, @dataJennifer, GETDATE());****
 ````



# Aula 04 - 21/08/2026
````sql
-- IN

SELECT *
FROM FUNCIONARIO AS F

LEFT JOIN TRABALHA_EM AS T
ON T.Fcpf = F.Cpf

LEFT JOIN PROJETO AS P
ON P.Projnumero = T.Pnr;

SELECT *
FROM FUNCIONARIO
WHERE Salario IN (25000, 30000);

SELECT CONCAT(F.Pnome, ' ' ,F.Unome) AS Nome, T.Pnr AS Numero_Projeto
FROM TRABALHA_EM AS T, FUNCIONARIO AS F
WHERE 
	F.Cpf = T.Fcpf
	AND Pnr IN (
		SELECT Pnr 
		FROM TRABALHA_EM 
		WHERE Fcpf = (
			SELECT Cpf 
			FROM FUNCIONARIO
			WHERE Pnome = 'Fernando')
			)
	AND F.Pnome <> 'Fernando'; -- diferente de

-- BETWEEN

SELECT *
FROM FUNCIONARIO
WHERE Salario BETWEEN 30000 AND 40000
AND Dnr = 5;

-- INNER JOIN

SELECT CONCAT(F.Pnome, ' ' ,F.Unome) AS Nome_completo, F.Endereco, D.Dnome AS Departamento
FROM FUNCIONARIO AS F
INNER JOIN DEPARTAMENTO AS D ON F.Dnr = D.Dnumero
WHERE F.Dnr = 5;


SELECT CONCAT(F.Pnome, ' ' ,F.Unome) AS Nome_completo, P.Projnome
FROM FUNCIONARIO AS F
INNER JOIN TRABALHA_EM AS T ON T.Fcpf = F.Cpf
INNER JOIN PROJETO AS P ON P.Projnumero = T.Pnr
WHERE P.Projnome = 'ProdutoX';

////

SELECT P.Projnumero, D.Dnumero, D.Dnome, D.Cpf_gerente, F.Unome, P.Projlocal, F.Datanasc,F.Endereco
FROM FUNCIONARIO AS F
INNER JOIN TRABALHA_EM AS T
ON T.Fcpf = F.Cpf

INNER JOIN PROJETO AS P
ON P.Projnumero = T.Pnr
INNER JOIN DEPARTAMENTO AS D
ON P.Dnum = D.Dnumero
WHERE P.Projlocal = 'Mauá'

-- LEFT JOIN

SELECT *
FROM DEPARTAMENTO AS D
LEFT JOIN FUNCIONARIO AS F
ON D.Dnumero = F.Dnr
WHERE F.Cpf IS NULL; 

-- RIGHT JOIN

SELECT *
FROM DEPARTAMENTO AS D
RIGHT JOIN FUNCIONARIO AS F
ON D.Dnumero = F.Dnr

-- CROSS/FULL JOIN

SELECT *
FROM FUNCIONARIO AS F
FULL JOIN DEPARTAMENTO AS D
ON F.Dnr = D.Dnumero
WHERE D.Dnumero IS NULL OR F.Cpf IS NULL;

-- SELF JOIN (quando a tabela se relaciona a ela mesma)
-- comparar linhas e posições hierarquicas

SELECT t1.Pnome, t2.Cpf_supervisor
FROM FUNCIONARIO AS t1
JOIN FUNCIONARIO AS t2
ON t1.Cpf = t2.Cpf
WHERE t2.Cpf_supervisor IS NOT NULL;


SELECT F.Pnome AS 'Funcionario',S.Unome AS 'Supervisor'
FROM FUNCIONARIO AS F

JOIN FUNCIONARIO AS S
ON F.Cpf_supervisor = S.Cpf_supervisor

ORDER BY S.Unome;

-- UNION/INTERSECT/EXCEPT

SELECT F.Pnome AS 'Nome', F.Sexo AS 'Sexo', F.Datanasc AS 'Data'
FROM FUNCIONARIO AS F
UNION
SELECT 
	D.Nome_dependente AS 'Nome',
	D.Sexo AS 'Sexo',
	D.Datanasc AS 'Data'
FROM DEPENDENTE AS D;
````




# Aula 03 - 14/08/2026

## Exercicio da Aula
```sql
-- Distinct
SELECT DISTINCT F.Salario
FROM FUNCIONARIO AS F;

SELECT DISTINCT F.Sexo
FROM FUNCIONARIO AS F;

-- WHERE
SELECT *
FROM FUNCIONARIO AS F
WHERE F.Pnome = 'Carlos';

-- AND
SELECT *
FROM FUNCIONARIO AS F
WHERE 
	F.Salario >= 30000
	AND F.Sexo = 'M';

-- OR
SELECT *
FROM FUNCIONARIO AS F
WHERE 
	F.Endereco LIKE '%São Paulo%' 
	OR F.Endereco LIKE '%Curitiba%';

-- NOT 
SELECT * 
FROM FUNCIONARIO AS F
WHERE 
	F.Endereco NOT LIKE '%SP%';

-- ORDER BY
SELECT 
    F.Pnome AS 'Nome',
	F.Unome AS 'Sobrenome',
	F.Salario AS 'Salario',
    (F.Salario + COALESCE(F.Bonus, 0)) * 12 AS Custo_Anual
FROM FUNCIONARIO AS F
ORDER BY (F.Salario + COALESCE(F.Bonus, 0)) * 12 DESC;

-- NULL
SELECT *
FROM FUNCIONARIO AS F
WHERE F.Cpf_supervisor IS NULL;

-- SELECT TOP/LIMIT
SELECT TOP 3
    F.Pnome AS 'Nome',
	F.Unome AS 'Sobrenome',
	F.Salario AS 'Salario',
    (F.Salario + COALESCE(F.Bonus, 0)) * 12 AS Custo_Anual
FROM FUNCIONARIO AS F
ORDER BY F.Salario DESC;

-- MIN() MAX()
SELECT
	MIN(F.Salario) AS 'Menor salario',
	MAX(F.Salario) AS 'Maior salario'
FROM FUNCIONARIO AS F

-- SELECT alinhado
SELECT *
FROM FUNCIONARIO AS F
WHERE 
	F.Salario = (SELECT MIN(Salario) FROM FUNCIONARIO);

-- Criação de variáveis
DECLARE @salario_min DECIMAL(10, 2);
SET @salario_min = (SELECT MIN(Salario) FROM FUNCIONARIO);
PRINT @salario_min;

SELECT *
FROM FUNCIONARIO AS F
WHERE 
	F.Salario = @salario_min;

-- COUNT()
SELECT COUNT(F.Cpf)
FROM FUNCIONARIO AS F;

SELECT COUNT(D.Nome_dependente)
FROM DEPENDENTE AS D;

SELECT
	(SELECT COUNT(F.Cpf)
FROM FUNCIONARIO AS F) +
	(SELECT COUNT(D.Nome_dependente)
FROM DEPENDENTE AS D)
	AS 'Qtd Pessoas';

-- AVG()
SELECT AVG(F.Salario)
FROM FUNCIONARIO AS F

-- Pessoas que ganham abaixo da media salarial
SELECT * 
FROM FUNCIONARIO AS F 
WHERE F.Salario < (SELECT AVG(Salario) FROM FUNCIONARIO)
ORDER BY F.Salario ASC;

-- SUM()
SELECT SUM(F.Salario) * 12 AS Custo_Anual
FROM FUNCIONARIO AS F;

-- LIKE
SELECT *
FROM FUNCIONARIO AS F
WHERE F.Datanasc LIKE '__72%';

```

# Aula 2
- Revisão da utlima aula
- estudo sobre tipos de dados, restrições - constraints
	
## Exercicio da Aula:  
    
```sql
-- Criando meu banco
CREATE DATABASE biblioteca;
DROP SCHEMA biblioteca;

-- Colocar o banco criado em uso
use biblioteca;

-- Criar o banco
CREATE TABLE Autor ( 
	id INT PRIMARY KEY,
    nome VARCHAR(151) NOT NULL,
    nacionalidade VARCHAR(74)
);

CREATE TABLE Editora(
	id_Editora INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100),
    cidade VARCHAR(50),
    site VARCHAR(100),
    ano_fundacao YEAR
);

CREATE TABLE Livro (
    ISBN CHAR(13) PRIMARY KEY,
    titulo VARCHAR(150) NOT NULL,
    ano_publicacao YEAR,
    fk_id_autor INT,
    fk_id_editora INT,

    FOREIGN KEY (fk_id_autor) REFERENCES Autor(id),
    FOREIGN KEY (fk_id_editora) REFERENCES Editora(id_Editora)
);

-- Remover a tabela livro
DROP TABLE Livro;

-- Adicionando FK via alteração
ALTER TABLE Livro 
ADD CONSTRAINT fk_Autor -- nome da restrição
FOREIGN KEY (fk_id_Autor) REFERENCES Autor (id);

-- Adicionando uma nova coluna na tabela Livro
ALTER TABLE Livro
ADD Genero TEXT; 

ALTER TABLE Autor
ADD COLUMN anoNascimento YEAR;

-- Removendo uma coluna 
ALTER TABLE Livro
DROP COLUMN Genero;

-- Modificar tipo de uma coluna
ALTER TABLE Autor
MODIFY COLUMN nacionalidade CHAR(2);

-- Alterando nome de uma coluna
ALTER TABLE Livro
CHANGE id ISBN VARCHAR(20);

-- Inserir
INSERT INTO Autor (id, nome, nacionalidade, anoNascimento) 
VALUES (1, "Machado de Assis", "Brasileiro", 1939);

INSERT INTO Autor
VALUES (2, "George Orwell", "Britânico", 1903); 

INSERT INTO editora(nome, cidade, site, ano_fundacao)
VALUES ("Companhia das Letras", "São Paulo", "www.cdi.br", 1986), 
	   ("Penguin", "Londres", "www.pg.ldn", 1935);
       
INSERT INTO Livro (titulo, ISBN, ano_publicacao, fk_id_autor, fk_id_editora)
VALUES ("Dom Casmurro", "9874689", 1910, 1, 1), ("1984", "7799654", 1949, 2, 2);

-- Update
UPDATE Autor
SET Autor.nacionalidade = "Brasileiro"
WHERE Autor.id = 2;

SELECT * FROM Livro;
SELECT * FROM Autor;

-- Query
SELECT l.titulo, l.ano_publicacao
FROM Livro as l
WHERE l.titulo LIKE "%Dom";

-- Query
SELECT l.titulo AS "Título", 
	   l.ano_publicacao AS "Ano de publicação", 
	   A.nome AS "Autor", 
	   A.nacionalidade AS "Nacionalidade", 
       CONCAT(A.nome, "/", A.nacionalidade) AS "Autor/Nacionalidade",
       e.nome AS "Editora"
FROM Livro AS l
JOIN Autor AS a ON l.fk_id_autor = A.id
JOIN Editora AS e ON l.fk_id_editora = e.id_editora; 
```

# Aula 1
- Explicação inicial e como funcionará a materia
- Revisão de banco de dados
- Modelo Entidade-Relacionamento Conceitual
- Tipos de cardinalidade
- 
     ## EX1.
  ```sql
      /* Lógico_2: */
      CREATE TABLE Funcionario (
          Cpf CHAR(14) PRIMARY KEY,
          Nome VARCHAR(100),
          DataNascimento DATE,
          Salario DECIMAL(10,2),
          Rua VARCHAR(100),
          Cep CHAR(9),
          Numero INTEGER,
          complemento VARCHAR(100)
      );
  ```



    <img width="940" height="296" alt="print" src="https://github.com/user-attachments/assets/ff2cb3ea-7efe-45c9-84a7-9ecdfc1594fc" />

  EX2.
  
  <img width="912" height="562" alt="captura 1" src="https://github.com/user-attachments/assets/8de837a5-2a49-412f-8f27-5efb00523124" />

  


  ## OBS:
  - 1.O banco de de dados é mais usado, pois ajuda a evitar a dupluicidade de dados
  
