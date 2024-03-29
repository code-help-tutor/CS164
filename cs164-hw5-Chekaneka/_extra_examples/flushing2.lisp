WeChat: cstutorcs
QQ: 749389476
Email: tutorcs@163.com
(print
(let ((x (open-out "/tmp/cs164/test.txt")))
    (do (output x "test")
    (input (open-in "/tmp/cs164/test.txt") 1))
)
)
