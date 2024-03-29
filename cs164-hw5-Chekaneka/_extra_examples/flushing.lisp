WeChat: cstutorcs
QQ: 749389476
Email: tutorcs@163.com
(do 
(let ((x (open-out "/tmp/cs164/test.txt"))) 
(do (output x "abc") 
(close-out x))) 
(let ((x (open-in "/tmp/cs164/test.txt"))) 
(do (print (input x 3)) 
(close-in x))) 
(let 
((x (open-in "/tmp/cs164/test.txt"))) 
(do (output stdout (input x 3)) 
(close-in x))))