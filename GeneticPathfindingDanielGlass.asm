.data
# WARNING!!!!!!!  THIS SIMULATION MAY CAUSE EPILEPSY.  THIS SIMULATION CONTAINS MULTIPLE COLORS IN A VERY FLASHY WAY.  IF YOU WISH TO CONTINUE WITH THE PROGRAM PLEASE COMMENT OUT THE 
# CODE LABLED IN THE UPDATE SECTION OF THE CODE LABLED WITH EXCLAMATION MARKS!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# 							_ _			_ _
#						       (_)_)	___________    (_)_)
#							 \\   /            \   //	
#							  \\ |  _      _    | //
#							   \\| |_|    |_|   |//	
#							    \|     /\       |/
#							     \             /
#							      |_|_|_|_|_|_|
#							      | | | | | | |
#							      \__________/
#								||    ||
#                                                              _||   _||
#							     (___) (___)

#inspiration for bitmap display elements denoted by XXXXXXXXXXXXX seperators derived from snake project by Shane Shafferman and Eric Deas (https://github.com/Misto423/Assembly-Snake)
#This project is what I'd like to very VERY loosely call a genetic algorithm seeing as it's my first time trying something like this.  If you're knowledgable about the topic, any
#feedback is appreciated.  

#The objective of this program is to run through many "generations" of many "animals" that are attempting to get to the "food".  Fitness is calculated by linear distance from the food.
#This may make the simulation stuck on a local minimum due to not calculating fitness based on a pathfinding algorithm, but for simplicity, I decided that the linear distance would be 
#enough.  Due to simplicity, it is also possible for the food to be placed in a closed location, but the animals are intended to get as close as possible.  A percentage of the fittest
#animals will reproduce and generate a mixed offspring. These offspring will be mutated to prevent stagnation.  I will also fill the rest of the population with first generation
#animals (completely random movement) in an effort to decrease stagnation.  This, however, will not entirely prevent stagnation, so after a few generations of non-changing fittest
#genes the program will conclude as it has reached its best answer.  I have hard coded the population amount as 32 for simplicity.  If you wish to modify the population size for 
#curiosity's sake you will have to change all values referring to population size in the code.  Feel free to change the colors and wall amounts, though :)

#Game Core information
#the program will continue to run until you stop it.  There is no "end condition" so when you see little growth or the objective has been reached feel free to restart the program

#be sure to use Unit width and height of 8
#display width and height of 512
#set bitmap base address to $gp (this is also from the snake project. I thought it was best so i didnt have to allocate space in data)
#sim settings
#mutation amount. (amount out of times you'd like to mutate a random gene) I've pre-set it to the amount I think yeilds the best results
mutAmount: .word 300
#Amount of obstacles cant be 0
wallAmount: .word 600

#pause time
pauseTime: .word 5

#Screen 
screenWidth: 	.word 64
screenHeight: 	.word 64

#Colors
animalColor: 	.word	0x8b4513	 # brown
backgroundColor:.word	0x228b22	 # forest green
wallColor:    .word	0x808080	 # grey	
foodColor: 	.word	0xffff00	 # bright yellow

#user prompts
getX: .asciiz "Input a X value for the food. (Must be between 1-62)"
getY: .asciiz "Input a Y value for the food. (Must be between 1-62)"

#food location
food_X: .byte 1
food_Y: .byte 1

#Population genes. 32 animals with 128 movements to be made. so i'll need a space of 2048 bytes.  Could use just 2 bits for up, down, left, right, 
#but I didn't want to mess with bitwise operations for simplicity
population:
.space 4096

fitGenes: #need space for the 4 most fit genes so 4*128
.space 512

prevGenes: #need space for the 4 most fit genes so 4*128
.space 512

tempGene:#will store front of one gene and back of another so 128 bytes
.space 128


#animal location array.  I think i am able to get away with using 1 byte for coordinate giving me 256 values for each axis since the window is only on a coordinate grid of 64*64. 
#as such i'll need a space of 32 animals * 1 byte per axis
animal_X: .space 32
animal_Y: .space 32

.text
#######################################
#Building terrain for this simulation
#######################################
main:

#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
# Clearing screen for next simulation
#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
	lw $a0, screenWidth
	lw $a1, backgroundColor
	mul $a2, $a0, $a0 #total number of pixels on screen
	mul $a2, $a2, 4 #align addresses
	add $a2, $a2, $gp #add base of gp
	add $a0, $gp, $zero #loop counter
FillLoop:
	beq $a0, $a2, ClearRegisters
	sw $a1, 0($a0) #store color
	addiu $a0, $a0, 4 #increment counter
	j FillLoop
	
ClearRegisters:

	li $v0, 0
	li $a0, 0
	li $a1, 0
	li $a2, 0
	li $a3, 0
	li $t0, 0
	li $t1, 0
	li $t2, 0
	li $t3, 0
	li $t4, 0
	li $t5, 0
	li $t6, 0
	li $t7, 0
	li $t8, 0
	li $t9, 0
	li $s0, 0
	li $s1, 0
	li $s2, 0
	li $s3, 0
	li $s4, 0		

#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
# Draw walls
#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
#first drawing border
DrawBorder:
	li $t1, 0	#load Y coordinate for the left border
	LeftLoop:
	move $a1, $t1	#move y coordinate into $a1
	li $a0, 0	# load x direction to 0, doesnt change
	jal CoordinateToAddress	#get screen coordinates
	move $a0, $v0	# move screen coordinates into $a0
	lw $a1, wallColor	#move color code into $a1
	jal DrawPixel	#draw the color at the screen location
	add $t1, $t1, 1	#increment y coordinate
	
	bne $t1, 64, LeftLoop	#loop through to draw entire left border
	
	li $t1, 0	#load Y coordinate for right border
	RightLoop:
	move $a1, $t1	#move y coordinate into $a1
	li $a0, 63	#set x coordinate to 63 (right side of screen)
	jal CoordinateToAddress	#convert to screen coordinates
	move $a0, $v0	# move coordinates into $a0
	lw $a1, wallColor	#move color data into $a1
	jal DrawPixel	#draw color at screen coordinates
	add $t1, $t1, 1	#increment y coordinate
	
	bne $t1, 64, RightLoop	#loop through to draw entire right border
	
	li $t1, 0	#load X coordinate for top border
	TopLoop:
	move $a0, $t1	# move x coordinate into $a0
	li $a1, 0	# set y coordinate to zero for top of screen
	jal CoordinateToAddress	#get screen coordinate
	move $a0, $v0	#  move screen coordinates to $a0
	lw $a1, wallColor	# store color data to $a1
	jal DrawPixel	#draw color at screen coordinates
	add $t1, $t1, 1 #increment X position
	
	bne $t1, 64, TopLoop #loop through to draw entire top border
	
	li $t1, 0	#load X coordinate for bottom border
	BottomLoop:
	move $a0, $t1	# move x coordinate to $a0
	li $a1, 63	# load Y coordinate for bottom of screen
	jal CoordinateToAddress	#get screen coordinates
	move $a0, $v0	#move screen coordinates to $a0
	lw $a1, wallColor	#put color data into $a1
	jal DrawPixel	#draw color at screen position
	add $t1, $t1, 1	#increment X coordinate
	
	bne $t1, 64, BottomLoop	# loop through to draw entire bottom border
#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
#Draw walls
#using $t0 as count
#loading wall amount into $t1
#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
DrawWalls:
	li $t0,0
	lw $t1,wallAmount
	wallLoop:
	#syscall for random int with a upper bound
	li $v0, 42
	#upper bound 61 (0 <= $a0 < $a1)
	li $a1, 62
	syscall
	#increment the X position so it doesnt draw on a border
	addiu $t2, $a0, 1
	syscall
	#increment the Y position so it doesnt draw on a border
	addiu $a1, $a0, 1
	move $a0,$t2
	jal CoordinateToAddress
	move $a0,$v0
	lw $a1, wallColor
	jal DrawPixel
	addiu $t0,$t0,1
	bne $t1,$t0,wallLoop
j begin
##################################################################
#Initializing Animal population with a random character for each movement
##################################################################
newPop:
la $t0,population
li $t1, 0#animal count
animalLoop:
li $t2,0#gene count
	geneLoop:
	#syscall for random int with a upper bound 3 for up down left right.
	li $v0, 42
	li $a1, 4
	syscall
	
	add $t3,$t2,$t0
	sb $a0,($t3)	#storing random between 0-3 in t0 address + incremented offset
	addiu $t2,$t2,1	#keeping track of genecount
	blt $t2,128,geneLoop
nextAnimal:
addiu $t0,$t0,128#next animal genes
addiu $t1,$t1,1#increment animal count
blt $t1,32,animalLoop#fall through if done
jr $ra

##################################################################
#starting simulation
##################################################################
begin:
jal newPop
##################################################################
#getting food location from user.  storing and drawing it
##################################################################
getInputX:
li $v0,51
la $a0,getX
syscall
blt $a1,0,getInputX #if invalid input
blt $a0,1,getInputX #if not on screen
bgt $a0,63,getInputX #if not on scred
sb $a0,food_X

getInputY:
li $v0,51
la $a0,getY
syscall
blt $a1,0,getInputY #if invalid input
blt $a0,1,getInputY #if not on screen
bgt $a0,63,getInputY #if not on scred
sb $a0,food_Y

##################################################################
#This is where we get into runtime
##################################################################

run:

drawFood:
	#drawing pixel
	lb $a0,food_X
	lb $a1,food_Y
	jal CoordinateToAddress
	move $a0,$v0
	lw $a1,foodColor
	jal DrawPixel

##################################################################
#setting animal coordinates in x arrray and y array to the center of the screen (31,31
##################################################################
li $t2,31#x y pos
li $t3,0 #counter
#storing coordinates
initPosLoop:
	la $t0,animal_X($t3)	#moving to current animal X
	la $t1,animal_Y($t3)	#moving to current animal Y
	sb $t2,($t0)	#storing value in X
	sb $t2,($t1)	#storing value in Y
	addiu $t3,$t3,1	#going to next animal
	blt $t3,32,initPosLoop
##################################################################
#simulating population
##################################################################
	#changing color 
	#syscall for random int with a upper bound 16777214 for random color for each population!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	lw $t0,wallColor
	randColor:
	li $v0, 42
	li $a1, 16777214
	syscall
	beq $a0,$t0,randColor
	sw $a0,animalColor
	#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!Comment this if you don't want random colors!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

	li $s1, 0 #movement frame (which gene we're on)
	frameUpdate:
	li $s0, 0#animal counter	
		animalUpdate:
		move $a0,$s0
		move $a1,$s1
		#seeing where it should go next move
		jal calcCoordinates
		#saving the supposed coordinates
		move $s2,$v0
		move $s3,$v1
		
		#making that an adress
		move $a0,$s2
		move $a1,$s3
		jal CoordinateToAddress
		
		#checking that address to see if it is valid move (if it's not a wall)
		move $a0,$v0
		jal checkCollision

		#passing $s2 and $s3 to set coordinates of this animal
		move $a0,$s2
		move $a1,$s3
		move $a2,$s0
	

		#if there was no collision set coordinates. otherwise new coordinates will not be set and that gene will not do anything
		beqz $v0,setCoordinates
		CoordsSet:
		#incrementing the animal
		addiu $s0,$s0,1
		blt $s0,32,animalUpdate#branch if there are still animals to go through
		#once all animals have had their frames updated i give the user time to see changes (this can be changed)
		j drawPopulation
		popDrawn:
		li $v0, 32
		lw $a0,pauseTime
		syscall
		
	addiu $s1,$s1,1
	blt $s1, 128, frameUpdate # if all frames havent been played update pixels
##################################################################
# Sim for this population is now done.  Now we calculate fitness.
##################################################################

#going through each animal and comparing their linear distance to food
li $s0,0 #counts through animals
li $s1,0 #keeps track of best animal
li $s2,0 #keeps track of second best
li $s3,0 #keeps track of third best
li $s4,0 #keeps track of fourth best
li $s5,64#max distance.  Anythng better will replace it
distLoop:
la $t0,animal_X
la $t1,animal_Y
#finding x and y of animal
add $t2,$t0,$s0
add $t3,$t1,$s0
lb $a0,($t2)
lb $a1,($t3)
#passing x and y to calcDist
jal calcDist
move $a0,$v0
ble $a0,$s5,setBest#less or equal so it's assured i get 4 fittest
bestSet:
addiu $s0,$s0,1#incrementing for next animal
blt $s0,32,distLoop#when it's done going through, start making the next population

makePop:
#store best animal genes
la $t0,population
la $t1,fitGenes
#converting animal to byte offset
mul $s1,$s1,128
mul $s2,$s2,128
mul $s3,$s3,128
mul $s4,$s4,128
#writing fit genes to the fitgenes label(keeps $t1 incremented
add $t2,$s1,$t0
jal writeFit
add $t2,$s2,$t0
jal writeFit
add $t2,$s3,$t0
jal writeFit
add $t2,$s4,$t0
jal writeFit
#fill population with random junk for the non-fit
jal newPop
#replace top 8 with fittest and their offspring
	#writing fittest genes to previous genes
	la $t0,prevGenes
	la $t1,fitGenes
	li $t2,0
	writeToPrev:
	add $t3,$t0,$t2#prevgenes+offset
	add $t4,$t1,$t2#fitgenes+offset
	lb $t5,($t4)#loading move from fitgenes
	sb $t5,($t3)#storing into prevgenes
	addiu $t2,$t2,1
	blt $t2,512,writeToPrev
	#splicing fittest genes.  Splicing 1st fit with 3rd fit and 2nd fit with 4th
	#generating random number between 16 and 115 for splicing point
	#syscall for random int with a upper bound 100
	li $v0, 42
	li $a1, 100
	syscall
	addi $a2,$a0,16 #making it greater than 16
	#splicing 1 and 3
	#calculating address of two animals
	la $a0,fitGenes#address of 1
	li $t0,2
	mul $a1,$t0,128
	add $a1,$a1,$a0#setting $a1 to location of 3rd animal
	jal splice
	#generating random number between 16 and 115 for splicing point
	#syscall for random int with a upper bound 100
	li $v0, 42
	li $a1, 100
	syscall
	addi $a2,$a0,16 #making it greater than 16
	#splicing 2 and 4
	#calculating address of two animals
	la $a0,fitGenes
	li $t0,1
	li $t1,3
	mul $t0,$t0,128
	mul $t1,$t1,128
	add $a1,$a0,$t1#setting $a1 to location of 4th animal
	add $a0,$a0,$t0#setting $a0 to location of 2nd animal
	jal splice
#writing fitgenes back to the population by replacing the top 1024 animal genes with fitgenes. Then setting the next 512 to the previous population's fittest
la $t0,population
la $t1,fitGenes
li $t6,0
twiceLoop:
	li $t2,0
	fitWriteLoop:
	add $t3,$t2,$t0#going to respective character for population
	add $t4,$t2,$t1#going to respective character for fitgenes
	lb $t5,($t4)#loading from fitgenes
	sb $t5,($t3)#storing to population
	addiu $t2,$t2,1
	blt $t2,512,fitWriteLoop
add $t0,$t0, 512#adding for next 512 byes in pop
addiu $t6,$t6,1
blt $t6,2,twiceLoop
	
#mutating random genes throughout the entire population to reduce stagnation.
#syscall for random int with a upper bound 4095 for random gene to mutate
la $t0,population
lw $t1,mutAmount
li $t2,0
mutLoop:
li $v0, 42
li $a1, 4096
syscall
add $t3,$a0,$t0#going to population gene pool at random offset $a0
#getting random gene to replace with
li $v0, 42
li $a1, 3
syscall
sb $a0,($t3)#storing random gene at random point
addiu $t2,$t2,1
blt $t2,$t1,mutLoop
#writing fittest genes of previous generation to 1024-1536 (these dont get mutated)
	la $t0,population
	addiu $t0,$t0,1024
	la $t1,prevGenes
	li $t2,0
	writePrevFit:
	add $t3,$t0,$t2#population+offset+256
	add $t4,$t1,$t2#fitgenes+offset
	lb $t5,($t4)#loading move from fitgenes
	sb $t5,($t3)#storing into population
	addiu $t2,$t2,1
	blt $t2,1536,writePrevFit
#new population is made. Run population again
j run
##################################################################
#calcDist
#takes $a0 -> animal x
#takes $a1 -> animal y
##################################################################
# returns linear distance to food in $v0
#lineardist = sqrt((X2-X1)*(X2-X1)+(Y2-Y1)*(Y2-Y1))
##################################################################
calcDist:
lb $t0,food_X
lb $t1,food_Y
sub $t2,$t0,$a0
sub $t3,$t1,$a1
mult $t2,$t2#squaring
mflo $t2
mult $t3,$t3#squaring
mflo $t3
add $a0,$t3,$t2#max number is 8192 so we dont need to worry about overflow since we're dealing with words at this point
#square root algorithm inspired from https://ww2.eng.famu.fsu.edu/~mpf/Architecture/simple-sqrt.s
li $t1,0
loop:	mul	$t0, $t1, $t1
	bgt	$t0, $a0, end	
	addi	$t1, $t1, 1
	j	loop
end:	addi	$v0, $t1, -1
jr $ra
##################################################################
#Writing fittest to fitgenes. Keeps $r1 incremented
##################################################################
writeFit:
li $t3,0 #counter
writeLoop:
lb $t4,($t2)
sb $t4,($t1)#storing that gene in fitgenes
addiu $t2,$t2,1
addiu $t1,$t1,1
addiu $t3,$t3,1
blt $t3,128,writeLoop
jr $ra
##################################################################
#Splice loop
#takes $a0->address of animal 1
#takes $a1->address of animal 2
#takes $a2->position of splicing
##################################################################
#modifies addresses to contain spliced genes no return
##################################################################
splice:
la $t0, tempGene
#this part combines 1st part of animal 1 with 2nd part of animal 2 in temp gene
li $t1,0
	frontLoop:#writing beginning x char to tempgene
	add $t2,$t1,$a0#animal gene1 +offset
	add $t3,$t1,$t0#tempgene + offset
	lb $t4,($t2)#loading from anim1 gene
	sb $t4,($t3)#storing to temp gene
	addiu $t1,$t1,1
	blt $t1,$a2,frontLoop
	
	backLoop:#writing ending 64-x char to tempgene
	add $t2,$t1,$a1#animal gene2 +offset
	add $t3,$t1,$t0#tempgene + offset
	lb $t4,($t2)#loading from animal 2 gene
	sb $t4,($t3)#storing to temp gene
	addiu $t1,$t1,1
	blt $t1,128,backLoop
#this part replaces the second portion of animal 2 with animal 1's second portion
move $t1,$a2 #going directly to second half
	
	anim2Loop:#writing ending 64-x char to tempgene
	add $t2,$t1,$a0#animal gene1 +offset
	add $t3,$t1,$a1#animal gene2 + offset
	lb $t4,($t2)#loading from anim1 gene
	sb $t4,($t3)#storing to anim2 gene
	addiu $t1,$t1,1
	blt $t1,128,anim2Loop
jr $ra
#finally setting animal 1's genes to the temp gene
li $t1,0

	anim1Loop:#writing beginning x char to tempgene
	add $t2,$t1,$a0#animal gene1 +offset
	add $t3,$t1,$t0#tempgene + offset
	lb $t4,($t3)#loading from tempgene
	sb $t4,($t2)#storing to anim1 gene
	addiu $t1,$t1,1
	blt $t1,128,anim1Loop

##################################################################
#Setting best 4 (for readability)
##################################################################
setBest:#setting the best
move $s5,$a0#setting min dist
move $s4,$s3#pushing 3rd best to 4th best
move $s3,$s2#pushing 2nd best to 3rd best
move $s2,$s1#pushing first best to second best
move $s1,$s0#setting animal of min dist
j bestSet
##################################################################
#Drawing animals based on position
##################################################################
drawPopulation:
la $t0,animal_X
la $t1,animal_Y

li $t2,0#counter
	drawPopulationLoop:
	add $t3,$t0,$t2#incrementing animal for x
	add $t4,$t1,$t2#incrementing animal for y
	lb $a0,($t3)#loading value from x
	lb $a1,($t4)#loading value from y
	jal CoordinateToAddress
	move $a0,$v0
	lw $a1,animalColor
	jal DrawPixel
	addiu $t2,$t2,1
	blt $t2,32,drawPopulationLoop
j popDrawn #this function is for readability.  only going to this function sequentially so i can get away with jumps

##################################################################
#calcCoordinates
#this function will take the existing x y coordinates and modify them based
#on one of the 4 random numbers denoting up(0),down(1),left(2),right(3)
#$a0 -> which animal we're looking at.
#$a1 -> current frame of movement (out of the 64)
##################################################################
#returns $v0 -> x coord (byte)
#returns $v1 -> y coord (byte)
##################################################################
calcCoordinates:
la $t0,animal_X
la $t1,animal_Y
li $t2,128 #genes per animal
la $t8,population

mul $t3,$a0,$t2 #offset of the animal we want
add $t4,$t8,$t3 #moving to that animal
add $t4,$t4,$a1 #moving to the frame we want

lb $t5,($t4)#getting gene

#getting x y coord
add $t0,$t0,$a0
add $t1,$t1,$a0
lb $t6,($t0)
lb $t7,($t1)

#seeing which direction to move
beq $t5,0,moveUp
beq $t5,1,moveDown
beq $t5,2,moveLeft
beq $t5,3,moveRight

moveUp:
move $v0,$t6
addiu $v1,$t7,-1
jr $ra
moveDown:
move $v0,$t6
addiu $v1,$t7,1
jr $ra
moveLeft:
addiu $v0,$t6,-1
move $v1,$t7
jr $ra
moveRight:
addiu $v0,$t6,1
move $v1,$t7
jr $ra

##################################################################
#setCoordinates
#takes $a0 -> x coords
#takes $a1 -> y coords
#takes $a2 -> which animal
#sets x and y array to the current position of that animal
##################################################################
#returns nothing
##################################################################

setCoordinates:
la $t0,animal_X
la $t1,animal_Y

#calculating address
add $t0,$t0,$a2
add $t1,$t1,$a2

#setting coordinates of animal to x and y
sb $a0,($t0)
sb $a1,($t1)

j CoordsSet

##################################################################
#checkCollision
#takes $a0 -> the address equivalent to a coordinate
#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
#Using color to determine collision was inspired by snake project
#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
#checks if the address is wall.  If it is, then it collides.
##################################################################
#returns $v0 -> a 0 or 1 based on collision (1 is collide)
##################################################################
checkCollision:
lw $t0,($a0)#loading color of address into $t0
lw $t1,wallColor#loading color of wall into $t1
seq $v0,$t0,$t1
jr $ra

#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
#CoordinateToAddress Function
# $a0 -> x coordinate
# $a1 -> y coordinate
#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
# returns $v0 -> the address of the coordinates for bitmap display
#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
CoordinateToAddress:
	lw $v0, screenWidth 	#Store screen width into $v0
	mul $v0, $v0, $a1	#multiply by y position
	add $v0, $v0, $a0	#add the x position
	mul $v0, $v0, 4		#multiply by 4
	add $v0, $v0, $gp	#add global pointerfrom bitmap display
	jr $ra			# return $v0

#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
#Draw Function
# $a0 -> Address position to draw at
# $a1 -> Color the pixel should be drawn
#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
# no return value
#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
DrawPixel:
	sw $a1, ($a0) 	#fill the coordinate with specified color
	jr $ra		#return
	
