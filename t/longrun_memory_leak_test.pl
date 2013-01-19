use Coro::LocalScalar::XS;
use Coro;
while(1){
				my $scalar;
			Coro::LocalScalar::XS->localize($scalar);
			
				async {
						$scalar = "thread 1";
						cede;
						die unless $scalar eq "thread 1";
						$scalar = "thread 1 rewrite";
						cede;
						die unless $scalar eq "thread 1 rewrite";
						# warn 1;
				};
				
				async {
						$scalar = "thread 2";
						cede;
						die unless $scalar eq "thread 2";
						$scalar = "thread 2 rewrite";
						cede;
						die unless $scalar eq "thread 2 rewrite";
				};
				
				cede;
				cede;
				cede;

}