PRGS =  baseml codeml basemlg mcmctree pamp evolver yn00 chi2 
CC = cc # cc, gcc, cl

CFLAGS = -O4 -funroll-loops -fomit-frame-pointer -finline-functions

#MAC OSX G5:
#CFLAGS = -mcpu=G5 -O4 -funroll-loops -fomit-frame-pointer -finline-functions

#MAC OSX intel:
#CFLAGS = -march=pentium-m -O4 -funroll-loops -fomit-frame-pointer -finline-functions

#CFLAGS = -O4
#CFLAGS = -fast
#CFLAGS = -m64 -march=opteron -mtune=opteron -ansi -O3 -funroll-loops -fomit-frame-pointer -finline-functions 
#CFLAGS = -march=athlon -mcpu=athlon -O4 -funroll-loops -fomit-frame-pointer -finline-functions
#CFLAGS = -march=pentiumpro -mcpu=pentiumpro -O4 -funroll-loops -fomit-frame-pointer -finline-functions 

LIBS = -lm # -lM

all : $(PRGS)

baseml : baseml.o tools.o
	$(CC) $(CFLAGS) -o $@ baseml.o tools.o $(LIBS)
basemlg : basemlg.o tools.o
	$(CC) $(CFLAGS) -o $@ basemlg.o tools.o $(LIBS)
codeml : codeml.o tools.o
	$(CC) $(CFLAGS) -o $@ codeml.o tools.o $(LIBS)
evolver : evolver.o tools.o 
	$(CC) $(CFLAGS) -o $@ evolver.o tools.o $(LIBS)
pamp : pamp.o tools.o 
	$(CC) $(CFLAGS) -o $@ pamp.o tools.o $(LIBS)
mcmctree : mcmctree.o tools.o
	$(CC) $(CFLAGS) -o $@ mcmctree.o tools.o $(LIBS)
yn00: yn00.c tools.o
	$(CC) $(CFLAGS) -o $@ yn00.c tools.o $(LIBS)
chi2 : chi2.c
	$(CC) $(CFLAGS) -o $@ chi2.c $(LIBS)

tools.o : paml.h tools.c
	$(CC) $(CFLAGS) -c tools.c
baseml.o : paml.h baseml.c treesub.c treespace.c
	$(CC) $(CFLAGS) -c baseml.c
basemlg.o : paml.h basemlg.c treesub.c
	$(CC) $(CFLAGS) -c basemlg.c
codeml.o : paml.h codeml.c treesub.c treespace.c
	$(CC) $(CFLAGS) -c codeml.c
evolver.o: evolver.c treesub.c treespace.c
	$(CC) $(CFLAGS) -c evolver.c
pamp.o : paml.h pamp.c treesub.c treespace.c
	$(CC) $(CFLAGS) -c pamp.c
mcmctree.o : paml.h mcmctree.c treesub.c treespace.c
	$(CC) $(CFLAGS) -c mcmctree.c
