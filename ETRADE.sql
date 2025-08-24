-- Veritabanındaki tüm tabloların içindeki kayıtları listele
SELECT * FROM USER_
SELECT * FROM ORDER_
SELECT * FROM ORDERDETAIL
SELECT * FROM BASKET
SELECT * FROM BASKETDETAIL
SELECT * FROM ITEM
SELECT * FROM ITEMCATEGORY
SELECT * FROM INVOICE
SELECT * FROM INVOICEDETAIL
SELECT * FROM PAYMENT
SELECT * FROM ADDRES
SELECT * FROM CITY
SELECT * FROM COUNTRY
SELECT * FROM DISTRICT
SELECT * FROM DISTRICT_STREET
SELECT * FROM TOWN
SELECT * FROM PasswordList
GO


-- Tablolardaki toplam satır sayılarını listele
SELECT 'USER_' AS TableName, COUNT(*) AS TotalRows FROM USER_
UNION ALL
SELECT 'BASKET', COUNT(*) FROM BASKET
UNION ALL
SELECT 'BASKETDETAIL', COUNT(*) FROM BASKETDETAIL
UNION ALL
SELECT 'ITEM', COUNT(*) FROM ITEM
UNION ALL
SELECT 'ORDER_', COUNT(*) FROM ORDER_
UNION ALL
SELECT 'ADDRES', COUNT(*) FROM ADDRES
UNION ALL
SELECT 'CITY', COUNT(*) FROM CITY
UNION ALL
SELECT 'TOWN', COUNT(*) FROM TOWN
UNION ALL
SELECT 'DISTRICT', COUNT(*) FROM DISTRICT
UNION ALL
SELECT 'INVOICE', COUNT(*) FROM INVOICE;
GO


-- Kullanıcıların cinsiyet dağılımı
SELECT GENDER, COUNT(*) AS Adet FROM USER_
GROUP BY GENDER;
GO


-- Kategori bazında ürün sayısı 
SELECT CATEGORY1, COUNT(*) AS UrunSayisi FROM ITEM
GROUP BY CATEGORY1;
GO


-- En çok sipariş veren 5 kullanıcı 

-- PATH 1
SELECT TOP 5 U.USERNAME_, COUNT(O.ID) AS SiparisSayisi
FROM USER_ U
JOIN ORDER_ O ON U.ID = O.USERID
GROUP BY U.USERNAME_
ORDER BY SiparisSayisi DESC;
GO
-- PATH 2
SELECT U.USERNAME_, COUNT(O.ID) AS SiparisSayisi
FROM USER_ U
JOIN ORDER_ O ON U.ID = O.USERID
GROUP BY U.USERNAME_
ORDER BY SiparisSayisi DESC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;
GO


-- Her kullanıcı için ilk sipariş tarihi, son sipariş tarihi ve toplam harcama bilgisi
SELECT 
    U.USERNAME_,
    U.NAMESURNAME,
    MIN(O.DATE_) AS IlkSiparisTarihi,
    MAX(O.DATE_) AS SonSiparisTarihi,
    SUM(OD.TOTALPRICE) AS ToplamHarcama
FROM USER_ U
JOIN ORDER_ O ON U.ID = O.USERID
JOIN ORDERDETAIL OD ON O.ID = OD.ORDERID
GROUP BY U.USERNAME_, U.NAMESURNAME
ORDER BY ToplamHarcama DESC;
GO


-- Aylık bazda toplam sipariş sayısı ve toplam ciro 
SELECT 
    FORMAT(DATE_, 'yyyy-MM') AS Ay,
    COUNT(*) AS SiparisSayisi,
    SUM(TOTALPRICE) AS ToplamCiro
FROM ORDER_ O
JOIN ORDERDETAIL OD ON O.ID = OD.ORDERID
GROUP BY FORMAT(DATE_, 'yyyy-MM')
ORDER BY Ay;
GO


-- Kategori bazında toplam satış cirosu 
SELECT 
    I.CATEGORY1,
    SUM(OD.TOTALPRICE) AS ToplamCiro
FROM ORDERDETAIL OD
JOIN ITEM I ON OD.ITEMID = I.ID
GROUP BY I.CATEGORY1
ORDER BY ToplamCiro DESC;

GO


-- En çok satan 10 ürün 
SELECT 
    I.ITEMNAME,
    SUM(OD.AMOUNT) AS ToplamAdet,
    SUM(OD.TOTALPRICE) AS ToplamCiro
FROM ORDERDETAIL OD
JOIN ITEM I ON OD.ITEMID = I.ID
GROUP BY I.ITEMNAME
ORDER BY ToplamAdet DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
GO


-- Kullanıcıları toplam harcamalarına göre segment bilgisi (Düşük, Orta, Yüksek)
WITH KullaniciHarcama AS (
    SELECT 
        U.ID,
        U.USERNAME_,
        SUM(OD.TOTALPRICE) AS ToplamHarcama
    FROM USER_ U
    JOIN ORDER_ O ON U.ID = O.USERID
    JOIN ORDERDETAIL OD ON O.ID = OD.ORDERID
    GROUP BY U.ID, U.USERNAME_
)
SELECT 
    USERNAME_,
    ToplamHarcama,
    CASE 
        WHEN ToplamHarcama < 1000 THEN 'Düşük'
        WHEN ToplamHarcama BETWEEN 1000 AND 5000 THEN 'Orta'
        ELSE 'Yüksek'
    END AS Segment
FROM KullaniciHarcama
ORDER BY ToplamHarcama DESC;

GO 


-- Kullanıcıları segmentlerine göre kaç kullanıcı olduğunu bilgisi
WITH KullaniciHarcama AS (

    SELECT 
        U.ID,
        U.USERNAME_,
        SUM(OD.TOTALPRICE) AS ToplamHarcama
    FROM USER_ U
    JOIN ORDER_ O ON U.ID = O.USERID
    JOIN ORDERDETAIL OD ON O.ID = OD.ORDERID
    GROUP BY U.ID, U.USERNAME_
),
KullaniciSegment AS (
    SELECT 
        USERNAME_,
        ToplamHarcama,
        CASE 
            WHEN ToplamHarcama < 1000 THEN 'Düşük'
            WHEN ToplamHarcama BETWEEN 1000 AND 5000 THEN 'Orta'
            ELSE 'Yüksek'
        END AS Segment
    FROM KullaniciHarcama
)
SELECT 
    Segment,
    COUNT(*) AS KullaniciSayisi
FROM KullaniciSegment
GROUP BY Segment
ORDER BY CASE Segment
            WHEN 'Düşük' THEN 1
            WHEN 'Orta' THEN 2
            WHEN 'Yüksek' THEN 3
         END;
GO


-- Toplam cirosu 100.000’den fazla olan şehirlerdeki sipariş sayısı ve toplam ciro bilgisi
SELECT 
    C.CITY AS Sehir,
    COUNT(DISTINCT O.ID) AS SiparisSayisi,
    SUM(OD.TOTALPRICE) AS ToplamCiro
FROM ORDER_ O
JOIN ORDERDETAIL OD ON O.ID = OD.ORDERID
JOIN ADDRES A ON O.ADDRESSID = A.ID
JOIN CITY C ON A.CITYID = C.ID
GROUP BY C.CITY
HAVING SUM(OD.TOTALPRICE) > 100000
ORDER BY ToplamCiro DESC;
GO


  -- Ödeme yöntemleri ve detay bilgisi 
  SELECT 
    PAYMENTTYPE,
    COUNT(*) AS KullanimSayisi,
    SUM(TOTALPRICE) AS ToplamCiro
FROM PAYMENT
WHERE ISOK = 1
GROUP BY PAYMENTTYPE
ORDER BY KullanimSayisi DESC;
GO


-- Her ürün kategorisi İLE ödeme yöntemi bazında toplam ciro ve işlem sayısı
SELECT 
    I.CATEGORY1,
    P.PAYMENTTYPE,
    COUNT(P.ID) AS IslemSayisi,
    SUM(P.TOTALPRICE) AS ToplamCiro
FROM PAYMENT P
JOIN BASKET B ON P.BASKETID = B.ID
JOIN ORDER_ O ON B.ID = O.BASKETID
JOIN ORDERDETAIL OD ON O.ID = OD.ORDERID
JOIN ITEM I ON OD.ITEMID = I.ID
WHERE P.ISOK = 1
GROUP BY I.CATEGORY1, P.PAYMENTTYPE
ORDER BY I.CATEGORY1, ToplamCiro DESC;
GO


-- Her şehir ve ödeme yöntemi bazında toplam ciro ve işlem sayısı
SELECT 
    C.CITY AS Sehir,
    P.PAYMENTTYPE,
    COUNT(P.ID) AS IslemSayisi,
    SUM(P.TOTALPRICE) AS ToplamCiro
FROM PAYMENT P
JOIN BASKET B ON P.BASKETID = B.ID
JOIN USER_ U ON B.USERID = U.ID
JOIN ADDRES A ON B.USERID = A.USERID
JOIN CITY C ON A.CITYID = C.ID
WHERE P.ISOK = 1
GROUP BY C.CITY, P.PAYMENTTYPE
ORDER BY C.CITY, ToplamCiro DESC;
GO


-- Her ödeme yöntemi için toplam işlem sayısı, ortalama işlem tutarı ve başarısız ödeme sayısı
SELECT 
    P.PAYMENTTYPE,
    COUNT(P.ID) AS ToplamIslemSayisi,
    SUM(P.TOTALPRICE) AS ToplamCiro,
    AVG(P.TOTALPRICE) AS OrtalamaIslemTutar,
    SUM(CASE WHEN P.ISOK = 0 OR P.ISOK IS NULL THEN 1 ELSE 0 END) AS BasarisizIslemSayisi
FROM PAYMENT P
GROUP BY P.PAYMENTTYPE
ORDER BY ToplamCiro DESC;
GO


-- Her şehir ve kategori için ödeme yöntemi bazında toplam ciro, işlem sayısı ve başarısız işlem sayısını listeleme. Ayrıca toplam ciro 50.000’den fazla olan grupları baz alma analizi
WITH OdemeAnalizi AS (
    SELECT 
        C.CITY AS Sehir,
        I.CATEGORY1 AS Kategori,
        P.PAYMENTTYPE,
        COUNT(P.ID) AS IslemSayisi,
        SUM(P.TOTALPRICE) AS ToplamCiro,
        SUM(CASE WHEN P.ISOK = 0 OR P.ISOK IS NULL THEN 1 ELSE 0 END) AS BasarisizIslemSayisi
    FROM PAYMENT P
    LEFT JOIN BASKET B ON P.BASKETID = B.ID
    LEFT JOIN ORDER_ O ON B.ID = O.BASKETID
    LEFT JOIN ORDERDETAIL OD ON O.ID = OD.ORDERID
    LEFT JOIN ITEM I ON OD.ITEMID = I.ID
    LEFT JOIN USER_ U ON B.USERID = U.ID
    LEFT JOIN ADDRES A ON U.ID = A.USERID
    LEFT JOIN CITY C ON A.CITYID = C.ID
    WHERE P.PAYMENTTYPE IS NOT NULL
    GROUP BY C.CITY, I.CATEGORY1, P.PAYMENTTYPE
    HAVING SUM(P.TOTALPRICE) > 50000
)
SELECT *
FROM OdemeAnalizi
ORDER BY ToplamCiro DESC, BasarisizIslemSayisi DESC;
GO


-- Her ay ve ödeme yöntemi bazında toplam ciro, işlem sayısı ve başarısız ödeme sayısı ve toplam ciro 50.000’den fazla olan ayların listesi
WITH OdemeZaman AS (
    SELECT
        FORMAT(P.DATE_, 'yyyy-MM') AS YilAy,
        P.PAYMENTTYPE,
        COUNT(P.ID) AS IslemSayisi,
        SUM(P.TOTALPRICE) AS ToplamCiro,
        SUM(CASE WHEN P.ISOK = 0 OR P.ISOK IS NULL THEN 1 ELSE 0 END) AS BasarisizIslemSayisi
    FROM PAYMENT P
    LEFT JOIN BASKET B ON P.BASKETID = B.ID
    LEFT JOIN ORDER_ O ON B.ID = O.BASKETID
    LEFT JOIN ORDERDETAIL OD ON O.ID = OD.ORDERID
    LEFT JOIN ITEM I ON OD.ITEMID = I.ID
    WHERE P.PAYMENTTYPE IS NOT NULL
    GROUP BY FORMAT(P.DATE_, 'yyyy-MM'), P.PAYMENTTYPE
    HAVING SUM(P.TOTALPRICE) > 50000
)
SELECT *
FROM OdemeZaman
ORDER BY YilAy, ToplamCiro DESC;


GO


--Her ay ve ödeme yöntemi bazında toplam ciro ve 3 aylık hareketli toplam ciro 
WITH OdemeZaman AS (
    SELECT
        FORMAT(P.DATE_, 'yyyy-MM') AS YilAy,
        P.PAYMENTTYPE,
        SUM(P.TOTALPRICE) AS ToplamCiro
    FROM PAYMENT P
    LEFT JOIN BASKET B ON P.BASKETID = B.ID
    WHERE P.ISOK = 1
    GROUP BY FORMAT(P.DATE_, 'yyyy-MM'), P.PAYMENTTYPE
)
SELECT 
    YilAy,
    PAYMENTTYPE,
    ToplamCiro,
    SUM(ToplamCiro) OVER (
        PARTITION BY PAYMENTTYPE 
        ORDER BY YilAy 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS Rolling3AylikCiro
FROM OdemeZaman
ORDER BY PAYMENTTYPE, YilAy;

GO


-- 2025 yılında kayıt olan kullanıcıları “Yeni”, öncesinde kayıt olan kullanıcıları “Eski” olarak sınıflandırınız. Her kullanıcı grubunun toplam harcama analizi
WITH KullaniciTip AS (
    SELECT 
        ID AS UserID,
        USERNAME_,
        CASE 
            WHEN YEAR(CREATEDDATE) = 2025 THEN 'Yeni'
            ELSE 'Eski'
        END AS KullaniciTipi
    FROM USER_
),
KullaniciHarcama AS (
    SELECT 
        KT.KullaniciTipi,
        SUM(OD.TOTALPRICE) AS ToplamHarcama
    FROM KullaniciTip KT
    JOIN ORDER_ O ON KT.UserID = O.USERID
    JOIN ORDERDETAIL OD ON O.ID = OD.ORDERID
    GROUP BY KT.KullaniciTipi
)
SELECT *
FROM KullaniciHarcama;

GO


-- Kullanıcıları 2025 yılında kayıt olanlar “Yeni”, öncesinde kayıt olanlar “Eski” olarak sınıflandırınız. Her kullanıcı için toplam harcamayı hesaplayınız ve toplam harcama değerine göre azalan şekilde sıralayınız.
WITH KullaniciTip AS (
    SELECT 
        ID AS UserID,
        USERNAME_,
        CASE 
            WHEN YEAR(CREATEDDATE) = 2025 THEN 'Yeni'
            ELSE 'Eski'
        END AS KullaniciTipi
    FROM USER_
),
KullaniciHarcama AS (
    SELECT 
        KT.UserID,
        KT.USERNAME_,
        KT.KullaniciTipi,
        SUM(OD.TOTALPRICE) AS ToplamHarcama
    FROM KullaniciTip KT
    LEFT JOIN ORDER_ O ON KT.UserID = O.USERID
    LEFT JOIN ORDERDETAIL OD ON O.ID = OD.ORDERID
    GROUP BY KT.UserID, KT.USERNAME_, KT.KullaniciTipi
)
SELECT *
FROM KullaniciHarcama
ORDER BY ToplamHarcama DESC;
GO


-- Kullanıcıları 2025 yılında kayıt olanlar “Yeni”, öncesinde kayıt olanlar “Eski” olarak sınıflandırınız; her kullanıcı için toplam sipariş sayısı, toplam harcama, ortalama sipariş tutarı, ödeme yöntemi bazında toplam ödeme sayısı ve başarısız ödeme sayısını hesaplayınız ve kullanıcı tipi bazında sıralayınız.
WITH KullaniciTip AS (
    SELECT 
        ID AS UserID,
        USERNAME_,
        CASE 
            WHEN YEAR(CREATEDDATE) = 2025 THEN 'Yeni'
            ELSE 'Eski'
        END AS KullaniciTipi
    FROM USER_
),
KullaniciHarcama AS (
    SELECT 
        KT.UserID,
        KT.USERNAME_,
        KT.KullaniciTipi,
        COUNT(DISTINCT O.ID) AS SiparisSayisi,
        SUM(OD.TOTALPRICE) AS ToplamHarcama,
        AVG(OD.TOTALPRICE) AS OrtalamaSiparisTutar
    FROM KullaniciTip KT
    LEFT JOIN ORDER_ O ON KT.UserID = O.USERID
    LEFT JOIN ORDERDETAIL OD ON O.ID = OD.ORDERID
    GROUP BY KT.UserID, KT.USERNAME_, KT.KullaniciTipi
),
KullaniciOdeme AS (
    SELECT 
        KT.UserID,
        KT.KullaniciTipi,
        P.PAYMENTTYPE,
        COUNT(P.ID) AS OdemeSayisi,
        SUM(CASE WHEN P.ISOK = 0 OR P.ISOK IS NULL THEN 1 ELSE 0 END) AS BasarisizOdeme
    FROM KullaniciTip KT
    LEFT JOIN BASKET B ON KT.UserID = B.USERID
    LEFT JOIN PAYMENT P ON B.ID = P.BASKETID
    GROUP BY KT.UserID, KT.KullaniciTipi, P.PAYMENTTYPE
)
SELECT 
    KH.UserID,
    KH.USERNAME_,
    KH.KullaniciTipi,
    KH.SiparisSayisi,
    KH.ToplamHarcama,
    KH.OrtalamaSiparisTutar,
    KO.PAYMENTTYPE,
    KO.OdemeSayisi,
    KO.BasarisizOdeme
FROM KullaniciHarcama KH
LEFT JOIN KullaniciOdeme KO ON KH.UserID = KO.UserID
ORDER BY KH.KullaniciTipi, KH.ToplamHarcama DESC;

GO


-- Kullanıcıları şehir ve kategori bazında RFM skorlarına göre segmentlere ayırınız ve segment dağılımını gösteriniz.
WITH KullaniciRFM AS (
    SELECT
        U.ID,
        U.USERNAME_,
        U.NAMESURNAME,
        DATEDIFF(DAY, MAX(O.DATE_), GETDATE()) AS Recency,
        COUNT(O.ID) AS Frequency,
        SUM(OD.TOTALPRICE) AS Monetary
    FROM USER_ U
    JOIN ORDER_ O ON U.ID = O.USERID
    JOIN ORDERDETAIL OD ON O.ID = OD.ORDERID
    GROUP BY U.ID, U.USERNAME_, U.NAMESURNAME
),
RFM_Skor AS (
    SELECT 
        USERNAME_,
        NAMESURNAME,
        Recency,
        Frequency,
        Monetary,
        CASE 
            WHEN Recency <= 30 THEN 5
            WHEN Recency <= 60 THEN 4
            WHEN Recency <= 90 THEN 3
            WHEN Recency <= 120 THEN 2
            ELSE 1
        END AS R_Skor,
        CASE 
            WHEN Frequency >= 50 THEN 5
            WHEN Frequency >= 30 THEN 4
            WHEN Frequency >= 20 THEN 3
            WHEN Frequency >= 10 THEN 2
            ELSE 1
        END AS F_Skor,
        CASE 
            WHEN Monetary >= 10000 THEN 5
            WHEN Monetary >= 5000 THEN 4
            WHEN Monetary >= 2000 THEN 3
            WHEN Monetary >= 1000 THEN 2
            ELSE 1
        END AS M_Skor
    FROM KullaniciRFM
)
SELECT
    USERNAME_,
    NAMESURNAME,
    Recency,
    Frequency,
    Monetary,
    R_Skor,
    F_Skor,
    M_Skor,
    CASE 
        WHEN R_Skor >= 4 AND F_Skor >= 4 AND M_Skor >= 4 THEN 'En Değerli'
        WHEN R_Skor >= 3 AND F_Skor >= 3 AND M_Skor >= 3 THEN 'Orta Değerli'
        WHEN R_Skor <= 2 AND F_Skor <= 2 AND M_Skor <= 2 THEN 'Potansiyel Kayıp'
        ELSE 'Normal'
    END AS Segment
FROM RFM_Skor
ORDER BY Segment DESC, Monetary DESC;
GO


-- RFM skorlarına göre kullanıcı segmentasyonu
WITH KullaniciRFM AS (
    SELECT
        U.ID,
        U.USERNAME_,
        U.NAMESURNAME,
        DATEDIFF(DAY, MAX(O.DATE_), GETDATE()) AS Recency,
        COUNT(O.ID) AS Frequency,
        SUM(OD.TOTALPRICE) AS Monetary
    FROM USER_ U
    JOIN ORDER_ O ON U.ID = O.USERID
    JOIN ORDERDETAIL OD ON O.ID = OD.ORDERID
    GROUP BY U.ID, U.USERNAME_, U.NAMESURNAME
),
RFM_Skor AS (
    SELECT 
        USERNAME_,
        NAMESURNAME,
        Recency,
        Frequency,
        Monetary,
        CASE 
            WHEN Recency <= 30 THEN 5
            WHEN Recency <= 60 THEN 4
            WHEN Recency <= 90 THEN 3
            WHEN Recency <= 120 THEN 2
            ELSE 1
        END AS R_Skor,
        CASE 
            WHEN Frequency >= 50 THEN 5
            WHEN Frequency >= 30 THEN 4
            WHEN Frequency >= 20 THEN 3
            WHEN Frequency >= 10 THEN 2
            ELSE 1
        END AS F_Skor,
        CASE 
            WHEN Monetary >= 10000 THEN 5
            WHEN Monetary >= 5000 THEN 4
            WHEN Monetary >= 2000 THEN 3
            WHEN Monetary >= 1000 THEN 2
            ELSE 1
        END AS M_Skor
    FROM KullaniciRFM
)
SELECT
    USERNAME_,
    NAMESURNAME,
    Recency,
    Frequency,
    Monetary,
    R_Skor,
    F_Skor,
    M_Skor,
    CASE 
        WHEN R_Skor >= 4 AND F_Skor >= 4 AND M_Skor >= 4 THEN 'En Değerli'
        WHEN R_Skor >= 3 AND F_Skor >= 3 AND M_Skor >= 3 THEN 'Orta Değerli'
        WHEN R_Skor <= 2 AND F_Skor <= 2 AND M_Skor <= 2 THEN 'Potansiyel Kayıp'
        ELSE 'Normal'
    END AS Segment
FROM RFM_Skor
ORDER BY Segment DESC, Monetary DESC;
GO


-- Kullanıcıları şehir ve kategori bazında RFM skorlarına göre segmentlere ayırınız ve segment dağılımını gösteriniz.
WITH KullaniciRFM AS (
    SELECT
        U.ID AS UserID,
        U.USERNAME_,
        U.NAMESURNAME,
        A.CITYID,
        DATEDIFF(DAY, MAX(O.DATE_), GETDATE()) AS Recency,
        COUNT(O.ID) AS Frequency,
        SUM(OD.TOTALPRICE) AS Monetary
    FROM USER_ U
    JOIN ORDER_ O ON U.ID = O.USERID
    JOIN ORDERDETAIL OD ON O.ID = OD.ORDERID
    JOIN ADDRES A ON O.ADDRESSID = A.ID
    GROUP BY U.ID, U.USERNAME_, U.NAMESURNAME, A.CITYID
),
RFM_Skor AS (
    SELECT 
        K.USERID,
        K.USERNAME_,
        K.NAMESURNAME,
        K.CITYID,
        R.CITY AS Sehir,
        K.Recency,
        K.Frequency,
        K.Monetary,
        CASE 
            WHEN K.Recency <= 30 THEN 5
            WHEN K.Recency <= 60 THEN 4
            WHEN K.Recency <= 90 THEN 3
            WHEN K.Recency <= 120 THEN 2
            ELSE 1
        END AS R_Skor,
        CASE 
            WHEN K.Frequency >= 50 THEN 5
            WHEN K.Frequency >= 30 THEN 4
            WHEN K.Frequency >= 20 THEN 3
            WHEN K.Frequency >= 10 THEN 2
            ELSE 1
        END AS F_Skor,
        CASE 
            WHEN K.Monetary >= 10000 THEN 5
            WHEN K.Monetary >= 5000 THEN 4
            WHEN K.Monetary >= 2000 THEN 3
            WHEN K.Monetary >= 1000 THEN 2
            ELSE 1
        END AS M_Skor
    FROM KullaniciRFM K
    JOIN CITY R ON K.CITYID = R.ID
),
KullaniciSegment AS (
    SELECT *,
        CASE 
            WHEN R_Skor >= 4 AND F_Skor >= 4 AND M_Skor >= 4 THEN 'En Değerli'
            WHEN R_Skor >= 3 AND F_Skor >= 3 AND M_Skor >= 3 THEN 'Orta Değerli'
            WHEN R_Skor <= 2 AND F_Skor <= 2 AND M_Skor <= 2 THEN 'Potansiyel Kayıp'
            ELSE 'Normal'
        END AS Segment
    FROM RFM_Skor
)
SELECT 
    Sehir,
    Segment,
    COUNT(*) AS KullaniciSayisi
FROM KullaniciSegment
GROUP BY Sehir, Segment
ORDER BY Sehir, 
         CASE Segment
            WHEN 'En Değerli' THEN 1
            WHEN 'Orta Değerli' THEN 2
            WHEN 'Normal' THEN 3
            WHEN 'Potansiyel Kayıp' THEN 4
         END;

GO


-- Kullanıcı bazında sepet ve sipariş davranışlarını analiz ediniz. Her kullanıcı için toplam sepet sayısını, tamamlanan sepet sayısını, tamamlanmamış sepet sayısını, ortalama ürün sayısını ve ortalama sepet tutarını, ayrıca tamamlanan sipariş sayısı ve toplam sipariş tutarını hesaplayınız ve toplam sepet sayısına göre azalan şekilde sıralayınız.
WITH SepetBilgi AS (
    SELECT 
        B.ID AS BasketID,
        B.USERID,
        COUNT(BD.ID) AS UrunSayisi,
        SUM(BD.TOTAL) AS SepetToplam,
        B.STATUS_ AS SepetDurumu
    FROM BASKET B
    LEFT JOIN BASKETDETAIL BD ON B.ID = BD.BASKETID
    GROUP BY B.ID, B.USERID, B.STATUS_
),
SiparisBilgi AS (
    SELECT 
        O.BASKETID,
        COUNT(OD.ID) AS SiparisUrunSayisi,
        SUM(OD.TOTALPRICE) AS SiparisToplam
    FROM ORDER_ O
    LEFT JOIN ORDERDETAIL OD ON O.ID = OD.ORDERID
    GROUP BY O.BASKETID
)
SELECT 
    S.USERID,
    COUNT(DISTINCT S.BasketID) AS ToplamSepetSayisi,
    COUNT(DISTINCT CASE WHEN SP.BASKETID IS NOT NULL THEN S.BasketID END) AS TamamlananSepetSayisi,
    COUNT(DISTINCT CASE WHEN SP.BASKETID IS NULL THEN S.BasketID END) AS TamamlanmayanSepetSayisi,
    AVG(S.UrunSayisi) AS OrtalamaUrunSayisiSepette,
    AVG(S.SepetToplam) AS OrtalamaSepetTutar,
    SUM(SP.SiparisUrunSayisi) AS TamamlananSiparisUrunSayisi,
    SUM(SP.SiparisToplam) AS ToplamSiparisTutar
FROM SepetBilgi S
LEFT JOIN SiparisBilgi SP ON S.BasketID = SP.BASKETID
GROUP BY S.USERID
ORDER BY ToplamSepetSayisi DESC;
GO


-- Her sipariş için yıl, ay, gün ve haftanın günü bilgilerini çıkarınız. Sipariş detaylarında hangi ürünün satıldığını, miktarını ve toplam tutarını gösteriniz. Günlük ve aylık toplam sipariş sayısını ve toplam ciroyu ürün bazında hesaplayınız. Sonuçları tarih ve ürün sırasına göre sıralayınız.
SELECT
    O.DATE_ AS SiparisTarihi,
    YEAR(O.DATE_) AS Yil,
    MONTH(O.DATE_) AS Ay,
    DAY(O.DATE_) AS Gun,
    DATENAME(WEEKDAY, O.DATE_) AS HaftaninGunu,
    I.ITEMNAME,
    I.CATEGORY1,
    I.CATEGORY2,
    I.CATEGORY3,
    SUM(OD.AMOUNT) AS ToplamUrunMiktari,
    SUM(OD.TOTALPRICE) AS ToplamCiro,
    COUNT(DISTINCT O.ID) AS SiparisSayisi
FROM ORDER_ O
JOIN ORDERDETAIL OD ON O.ID = OD.ORDERID
JOIN ITEM I ON OD.ITEMID = I.ID
GROUP BY 
    O.DATE_, 
    I.ITEMNAME, 
    I.CATEGORY1, 
    I.CATEGORY2, 
    I.CATEGORY3
ORDER BY O.DATE_, I.ITEMNAME;
GO


-- Her kullanıcı için, her ürün ve kategori bazında, yıl, ay, gün ve haftanın günü bilgilerini çıkarınız. Sipariş sayısını, toplam ürün miktarını ve toplam ciroyu hesaplayınız. Sonuçları kullanıcı, ürün ve tarih sırasına göre sıralayınız.
SELECT
    U.ID AS UserID,
    U.USERNAME_ AS KullaniciAdi,
    O.DATE_ AS SiparisTarihi,
    YEAR(O.DATE_) AS Yil,
    MONTH(O.DATE_) AS Ay,
    DAY(O.DATE_) AS Gun,
    DATENAME(WEEKDAY, O.DATE_) AS HaftaninGunu,
    I.ITEMNAME,
    I.CATEGORY1,
    I.CATEGORY2,
    I.CATEGORY3,
    SUM(OD.AMOUNT) AS ToplamUrunMiktari,
    SUM(OD.TOTALPRICE) AS ToplamCiro,
    COUNT(DISTINCT O.ID) AS SiparisSayisi
FROM ORDER_ O
JOIN ORDERDETAIL OD ON O.ID = OD.ORDERID
JOIN ITEM I ON OD.ITEMID = I.ID
JOIN USER_ U ON O.USERID = U.ID
GROUP BY 
    U.ID, U.USERNAME_,
    O.DATE_,
    I.ITEMNAME, 
    I.CATEGORY1, 
    I.CATEGORY2, 
    I.CATEGORY3
ORDER BY UserID, SiparisTarihi, ITEMNAME;
GO


-- Haftanın günleri bazında sipariş analizi yapınız: Haftanın günleri için toplam sipariş sayısını, toplam ciroyu ve ortalama sipariş tutarını hesaplayınız
WITH SiparisToplam AS (
    SELECT
        O.ID AS OrderID,
        DATENAME(WEEKDAY, O.DATE_) AS HaftaninGunu,
        SUM(OD.TOTALPRICE) AS SiparisToplamCiro
    FROM ORDER_ O
    JOIN ORDERDETAIL OD ON O.ID = OD.ORDERID
    GROUP BY O.ID, DATENAME(WEEKDAY, O.DATE_)
)
SELECT
    HaftaninGunu,
    COUNT(OrderID) AS ToplamSiparisSayisi,
    SUM(SiparisToplamCiro) AS ToplamCiro,
    AVG(SiparisToplamCiro) AS OrtalamaSiparisTutari
FROM SiparisToplam
GROUP BY HaftaninGunu

GO


-- Kullanıcıların RFM segmentlerinin zaman içindeki değişim analizi 
-- Amaç: Dinamik segment analizi yapmak, kullanıcıların her ay “En Değerli”, “Orta Değerli”, “Normal” veya “Potansiyel Kayıp” segmentlerinden hangisine ait olduğunu takip etmek
WITH AyBazliSiparis AS (
    SELECT
        U.ID AS UserID,
        U.USERNAME_,
        FORMAT(O.DATE_, 'yyyy-MM') AS YilAy,
        MAX(O.DATE_) AS SonSiparisTarihi,
        COUNT(O.ID) AS Frequency,
        SUM(OD.TOTALPRICE) AS Monetary
    FROM USER_ U
    JOIN ORDER_ O ON U.ID = O.USERID
    JOIN ORDERDETAIL OD ON O.ID = OD.ORDERID
    GROUP BY U.ID, U.USERNAME_, FORMAT(O.DATE_, 'yyyy-MM')
),
AyBazliRFM AS (
    SELECT
        UserID,
        USERNAME_,
        YilAy,
        DATEDIFF(DAY, SonSiparisTarihi, GETDATE()) AS Recency,
        Frequency,
        Monetary,
        -- R Skor
        CASE 
            WHEN DATEDIFF(DAY, SonSiparisTarihi, GETDATE()) <= 30 THEN 5
            WHEN DATEDIFF(DAY, SonSiparisTarihi, GETDATE()) <= 60 THEN 4
            WHEN DATEDIFF(DAY, SonSiparisTarihi, GETDATE()) <= 90 THEN 3
            WHEN DATEDIFF(DAY, SonSiparisTarihi, GETDATE()) <= 120 THEN 2
            ELSE 1
        END AS R_Skor,
        -- F Skor
        CASE 
            WHEN Frequency >= 50 THEN 5
            WHEN Frequency >= 30 THEN 4
            WHEN Frequency >= 20 THEN 3
            WHEN Frequency >= 10 THEN 2
            ELSE 1
        END AS F_Skor,
        -- M Skor
        CASE 
            WHEN Monetary >= 10000 THEN 5
            WHEN Monetary >= 5000 THEN 4
            WHEN Monetary >= 2000 THEN 3
            WHEN Monetary >= 1000 THEN 2
            ELSE 1
        END AS M_Skor
    FROM AyBazliSiparis
)
SELECT
    YilAy,
    UserID,
    USERNAME_,
    Recency,
    Frequency,
    Monetary,
    R_Skor,
    F_Skor,
    M_Skor,
    CASE 
        WHEN R_Skor >= 4 AND F_Skor >= 4 AND M_Skor >= 4 THEN 'En Değerli'
        WHEN R_Skor >= 3 AND F_Skor >= 3 AND M_Skor >= 3 THEN 'Orta Değerli'
        WHEN R_Skor <= 2 AND F_Skor <= 2 AND M_Skor <= 2 THEN 'Potansiyel Kayıp'
        ELSE 'Normal'
    END AS Segment
FROM AyBazliRFM

ORDER BY UserID
GO


-- Günlük, haftalık ve aylık satış trendi 
SELECT
    CAST(O.DATE_ AS DATE) AS Tarih,
    COUNT(DISTINCT O.ID) AS GunlukSiparisSayisi,
    SUM(OD.TOTALPRICE) AS GunlukToplamCiro
FROM ORDER_ O
JOIN ORDERDETAIL OD ON O.ID = OD.ORDERID
GROUP BY CAST(O.DATE_ AS DATE)
ORDER BY Tarih;

GO

SELECT
    DATEPART(YEAR, O.DATE_) AS Yil,
    DATEPART(WEEK, O.DATE_) AS HaftaNo,
    COUNT(DISTINCT O.ID) AS HaftalikSiparisSayisi,
    SUM(OD.TOTALPRICE) AS HaftalikToplamCiro
FROM ORDER_ O
JOIN ORDERDETAIL OD ON O.ID = OD.ORDERID
GROUP BY DATEPART(YEAR, O.DATE_), DATEPART(WEEK, O.DATE_)
ORDER BY Yil, HaftaNo;

GO

SELECT
    FORMAT(O.DATE_, 'yyyy-MM') AS YilAy,
    COUNT(DISTINCT O.ID) AS AylikSiparisSayisi,
    SUM(OD.TOTALPRICE) AS AylikToplamCiro
FROM ORDER_ O
JOIN ORDERDETAIL OD ON O.ID = OD.ORDERID
GROUP BY FORMAT(O.DATE_, 'yyyy-MM')
ORDER BY YilAy;

-- NOT !!! Günlük raporda saat bilgisini atıp sadece tarih kısmını almak için CAST, haftalık raporda yıl ve hafta numarasını ayrı ayrı alıp gruplamak için DATEPART, aylık raporda yıl ve ayı tek bir string olarak gruplayabilmek için FORMAT kullanılır.
GO

-- Şehir ve Bölge Bazlı Ciro ve Sipariş Yoğunluğu Analizi
SELECT
    C.CITY AS Sehir,
    D.DISTRICT AS Bolge,
    COUNT(DISTINCT O.ID) AS SiparisSayisi,
    SUM(OD.TOTALPRICE) AS ToplamCiro,
    AVG(OD.TOTALPRICE) AS OrtalamaSiparisTutari
FROM ORDER_ O
JOIN ORDERDETAIL OD ON O.ID = OD.ORDERID
JOIN ADDRES A ON O.ADDRESSID = A.ID
JOIN CITY C ON A.CITYID = C.ID
JOIN DISTRICT D ON A.DISTRICTID = D.ID
GROUP BY C.CITY, D.DISTRICT
ORDER BY Sehir

GO
 

-- Şehir ve Bölge Bazında Ödeme Yöntemine Göre Ciro ve Sipariş Sayısı Analizi
WITH OdemeAnalizi AS (
    SELECT
        C.CITY AS Sehir,
        D.DISTRICT AS Bolge,
        P.PAYMENTTYPE,
        COUNT(P.ID) AS IslemSayisi,
        SUM(P.TOTALPRICE) AS ToplamCiro,
        SUM(CASE WHEN P.ISOK = 0 OR P.ISOK IS NULL THEN 1 ELSE 0 END) AS BasarisizIslemSayisi
    FROM PAYMENT P
    JOIN BASKET B ON P.BASKETID = B.ID
    JOIN ORDER_ O ON B.ID = O.BASKETID
    JOIN ORDERDETAIL OD ON O.ID = OD.ORDERID
    JOIN ADDRES A ON B.USERID = A.USERID
    JOIN CITY C ON A.CITYID = C.ID
    JOIN DISTRICT D ON A.DISTRICTID = D.ID
    WHERE P.PAYMENTTYPE IS NOT NULL
    GROUP BY C.CITY, D.DISTRICT, P.PAYMENTTYPE
    HAVING SUM(P.TOTALPRICE) > 50000
)
SELECT *
FROM OdemeAnalizi
ORDER BY Sehir

GO
